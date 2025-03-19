from flask import Flask, render_template, jsonify, request, send_from_directory
import json
import os
from pathlib import Path

app = Flask(__name__, static_folder='static')

def load_flower_data():
    """加载所有花卉数据"""
    data_dir = Path(__file__).parent / 'static' / 'data'
    flowers = []
    for file in data_dir.glob('*.json'):
        with open(file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            # 从文件名获取ID（去掉前缀和扩展名）
            file_id = file.stem.replace('data_', '')
            flowers.append({
                'id': file_id,
                'name': data['基础信息']['名称']['中文名'],
                'data': data
            })
    return flowers

@app.route('/')
def index():
    """渲染主页"""
    return render_template('index.html')

@app.route('/api/plants')
def get_plants():
    """获取所有花卉列表"""
    flowers = load_flower_data()
    # 只返回必要的列表信息
    return jsonify([{
        'id': flower['id'],
        'name': flower['name']
    } for flower in flowers])

@app.route('/resources/<path:filename>')
def serve_resource(filename):
    """提供静态资源文件"""
    try:
        return send_from_directory('static/data', filename)
    except Exception as e:
        app.logger.error(f"Error serving file {filename}: {str(e)}")
        return jsonify({'error': '文件访问失败'}), 403

@app.route('/api/flowers/<flower_name>')
def get_flower(flower_name):
    """获取指定花卉的详细信息"""
    flowers = load_flower_data()
    for flower in flowers:
        if flower['name'] == flower_name:
            return jsonify(flower['data'])
    return jsonify({'error': '未找到该花卉'}), 404

if __name__ == '__main__':
    app.run(debug=True)
