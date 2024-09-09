from flask import Flask, request, jsonify
from flask_cors import CORS
import subprocess
import os

app = Flask(__name__)
CORS(app)

PG_MAJOR = '16'

def exec(command):
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = process.communicate()
    print(f'Command: {command}', f'Output: {output}', f'Error: {error}')
    return output, error


@app.route('/exec', methods=['POST'])
def api_exec():
    data = request.json
    token = data['token']
    command = data['command']
    if token == os.environ['TOKEN']:
        output, error = exec(command)
        return jsonify({'output': output.decode('utf-8'), 'error': error.decode('utf-8')})
    else:
        return jsonify({'error': 'Invalid token'})
    

@app.route('/ping', methods=['POST'])
def api_ping():
    return jsonify({'message': 'pong'})


def init_postgresql(pgdata):
    exec(f'su -c "pg_ctl -D {pgdata} initdb" postgres')


    
def start_postgresql(pgdata, pglog):
    exec(f'su -c "pg_ctl -D {pgdata} -l {pglog} start" postgres')


def stop_postgresql():
    exec('service postgresql stop')


def exec_sql(sql, database='postgres'):
    exec(f'su -c \"psql -U postgres -d {database} -c "{sql}"\" postgres')


if __name__ == '__main__':
    costum_pg_data_dir = '/postgres-ha/data/postgresql'
    costum_pg_log_dir = '/postgres-ha/log/postgresql'
    costum_pg_log_file = costum_pg_log_dir + '/postgresql.log'
    os.makedirs(costum_pg_data_dir, exist_ok=True)
    os.makedirs(costum_pg_log_dir, exist_ok=True)
    exec(f'chown -R postgres:postgres {costum_pg_data_dir}')
    exec(f'chown -R postgres:postgres {costum_pg_log_dir}')
    if not os.listdir(costum_pg_data_dir):
        init_postgresql(costum_pg_data_dir)
    start_postgresql(costum_pg_data_dir, costum_pg_log_file)
    app.run(host='0.0.0.0', port=54323, debug=False)


"""
3FPF1wL6Xsve25zkYkkeYjJ8Ywd2RAvXJx59imb5
pg_createcluster 16 main
pg_conftool 16 main set listen_addresses '*'
pg_conftool 16 main set shared_preload_libraries citus 
sudo docker run -d \
                --name=test \
                -p 54322:5432 \
                -p 54323:54323 \
                -v /postgres-ha/data:/postgres-ha/data \
                -v /postgres-ha/log:/postgres-ha/log \
                test
sudo docker exec -it test bash
sudo docker stop test && sudo docker rm test && sudo docker rmi test
"""
