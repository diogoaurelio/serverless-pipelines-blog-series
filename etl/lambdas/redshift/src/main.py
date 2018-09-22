import urllib
import pg8000
import boto3
import os
import logging

IAM_ROLE = os.environ['IAM_ROLE']
DB_NAME = os.environ['DB_NAME']
DB_USER = os.environ['DB_USER']
DB_PORT = os.environ['DB_PORT']
DB_HOST = os.environ['DB_HOST']
DB_TABLE = os.environ['DB_TABLE']
DB_PW_PARAM = os.environ['DB_PW_PARAM']


logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _get_db_password(with_decryption: bool) -> str:
    """ Get password from AWS SSM parameter Store """
    ssm = boto3.client('ssm')
    res = ssm.get_parameter(Name=DB_PW_PARAM, WithDecryption=with_decryption)
    if res and res.get('Parameter', {}).get('Value'):
        return res['Parameter']['Value']
    raise Exception("Failed to retrieve DB password: {}".format(res))


def _get_pg_client(auto_commit=True, ssl=True):
    db_password = _get_db_password(with_decryption=True)
    client = pg8000.connect(user=DB_USER, host=DB_HOST, port=int(DB_PORT),
                            database=DB_NAME, password=db_password, ssl=ssl)
    client.autocommit = auto_commit
    cur = client.cursor()
    return client, cur


def _get_base_copy_cmd(table: str, bucket: str, key: str) -> str:
    """ Base of any Redshift Copy Command """
    return """
            COPY {table}
            FROM 's3://{bucket}/{key}'
            IAM_ROLE '{iam_role}'
            """.format(table=table, bucket=bucket,
                       key=key, iam_role=IAM_ROLE)


def _get_csv_copy_cmd(table: str, bucket: str, key: str) -> str:
    """ Example for import CSV files """
    base_qry = _get_base_copy_cmd(table=table, bucket=bucket, key=key)
    return "{base_query} delimiter '{delimiter}' IGNOREHEADER 1".format(
        base_query=base_qry, delimiter=',')


def build_copy_command(bucket: str, key: str) -> str:
    """ Extracts copy command params based on key """
    key_split = key.split("/")
    table = _get_table(key_split)
    qry = _get_csv_copy_cmd(table=table, bucket=bucket, key=key)
    logger.info(qry)
    return qry


def handler(event, context):
    records = event.get('Records')
    s3_data = record.get('s3', {})
    bucket = s3_data.get('bucket', {}).get('name')
    key = s3_data.get('object', {}).get('key')
    key = urllib.parse.unquote_plus(key, encoding='utf-8')

    logger.info("Loading the following S3 object into Redshift: '{}/{}'".format(bucket, key))
    query = build_copy_command(bucket=bucket, key=key)    
    
    conn, cur = _get_pg_client()
    exc = None
    try:
        cur.execute(query)
    except Exception as e:
        logger.error("Copy command to Redshift failed while dealing with key: {}/{}".format(bucket, key))
        exc = e
    
    cur.close()
    conn.close()
    if exc:
        raise exc
