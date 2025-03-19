from flask import Flask, render_template, jsonify, request
import json
import os
from pathlib import Path

app = Flask(__name__)

def load_flower_data():
    """加载所有花卉数据"""
    data_dir = Path(__file__).parent / 'static' / 'data'
    flowers = []
    for file in data_dir.glob('*.json'):
        with open(file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            flowers.append({
                'name': data['基础信息']['名称']['中文名'],
                'data': data
            })
    return flowers

@app.route('/')
def index():
    """渲染主页"""
    flowers = load_flower_data()
    return render_template('index.html.bak', flowers=flowers)

@app.route('/api/flowers')
def get_flowers():
    """获取所有花卉数据"""
    flowers = load_flower_data()
    return jsonify(flowers)

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
