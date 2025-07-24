import os
import time
import logging
import json
import requests
import pandas as pd
import psycopg2
import pymysql
import spacy
import numpy as np
from sklearn.cluster import DBSCAN
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.feature_extraction.text import TfidfVectorizer
from datetime import datetime, timedelta

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 从环境变量获取配置
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgres")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_USER = os.getenv("POSTGRES_USER", "postgres")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "strongpassword")
RASA_DB_NAME = os.getenv("RASA_DB_NAME", "rasa_db")
OSTICKET_DB_NAME = os.getenv("OSTICKET_DB_NAME", "osticket_db")

BOOKSTACK_URL = os.getenv("BOOKSTACK_URL", "http://bookstack:80")
BOOKSTACK_API_TOKEN = os.getenv("BOOKSTACK_API_TOKEN", "your_api_token")
BOOKSTACK_API_SECRET = os.getenv("BOOKSTACK_API_SECRET", "your_api_secret")

# 加载 NLP 模型
nlp = spacy.load("zh_core_web_sm")
vectorizer = TfidfVectorizer(max_features=1000, stop_words='english')

class KnowledgeExtractor:
    def __init__(self):
        self.rasa_conn = None
        self.osticket_conn = None
        self.conversations = []
        self.tickets = []
        self.knowledge_items = []
        
    def connect_to_databases(self):
        """连接到 Rasa 和 osTicket 数据库"""
        try:
            # 连接到 Rasa 数据库
            self.rasa_conn = psycopg2.connect(
                host=POSTGRES_HOST,
                port=POSTGRES_PORT,
                user=POSTGRES_USER,
                password=POSTGRES_PASSWORD,
                dbname=RASA_DB_NAME
            )
            logger.info("成功连接到 Rasa 数据库")
            
            # 连接到 osTicket 数据库 (MySQL)
            self.osticket_conn = pymysql.connect(
                host='mysql',
                port=3306,
                user='osticket',
                password=os.getenv('MYSQL_PASSWORD', 'osticket_password'),
                database='osticket',
                charset='utf8mb4'
            )
            logger.info("成功连接到 osTicket 数据库")
            
            return True
        except Exception as e:
            logger.error(f"连接数据库时出错: {str(e)}")
            return False
    
    def extract_conversations(self, days=7):
        """从 Rasa 数据库提取最近的对话"""
        if not self.rasa_conn:
            logger.error("未连接到 Rasa 数据库")
            return
        
        try:
            # 计算日期范围
            cutoff_date = datetime.now() - timedelta(days=days)
            
            # 查询对话数据
            cursor = self.rasa_conn.cursor()
            query = """
            SELECT sender_id, events
            FROM events
            WHERE timestamp > %s
            ORDER BY timestamp DESC
            """
            cursor.execute(query, (cutoff_date.timestamp(),))
            
            # 处理结果
            conversations = []
            for sender_id, events_json in cursor.fetchall():
                try:
                    events = json.loads(events_json)
                    conversation = {
                        "sender_id": sender_id,
                        "messages": []
                    }
                    
                    for event in events:
                        if event.get("event") == "user" and "text" in event:
                            conversation["messages"].append({
                                "role": "user",
                                "text": event["text"]
                            })
                        elif event.get("event") == "bot" and "text" in event:
                            conversation["messages"].append({
                                "role": "bot",
                                "text": event["text"]
                            })
                    
                    if len(conversation["messages"]) > 0:
                        conversations.append(conversation)
                except Exception as e:
                    logger.warning(f"处理对话 {sender_id} 时出错: {str(e)}")
            
            self.conversations = conversations
            logger.info(f"从 Rasa 数据库提取了 {len(conversations)} 个对话")
            
        except Exception as e:
            logger.error(f"提取对话时出错: {str(e)}")
    
    def extract_tickets(self, days=30):
        """从 osTicket 数据库提取已解决的工单"""
        if not self.osticket_conn:
            logger.error("未连接到 osTicket 数据库")
            return
        
        try:
            # 计算日期范围
            cutoff_date = datetime.now() - timedelta(days=days)
            
            # 查询已解决的工单
            cursor = self.osticket_conn.cursor()
            query = """
            SELECT t.ticket_id, t.number, te.title as subject, t.created, t.updated, 
                   t.status_id, te.body as description
            FROM ost_ticket t
            JOIN ost_thread th ON t.ticket_id = th.object_id AND th.object_type = 'T'
            JOIN ost_thread_entry te ON th.id = te.thread_id
            WHERE t.status_id = 3 -- 假设状态 3 表示已解决
              AND t.updated > %s
            ORDER BY t.updated DESC
            """
            cursor.execute(query, (cutoff_date.strftime('%Y-%m-%d'),))
            
            # 处理结果
            tickets = []
            for row in cursor.fetchall():
                ticket = {
                    "ticket_id": row[0],
                    "number": row[1],
                    "subject": row[2],
                    "created": row[3],
                    "updated": row[4],
                    "status_id": row[5],
                    "description": row[6],
                    "resolution": row[6]  # 暂时使用description作为resolution
                }
                tickets.append(ticket)
            
            self.tickets = tickets
            logger.info(f"从 osTicket 数据库提取了 {len(tickets)} 个已解决的工单")
            
        except Exception as e:
            logger.error(f"提取工单时出错: {str(e)}")
    
    def analyze_conversations(self):
        """分析对话，识别常见问题和解决方案"""
        if not self.conversations:
            logger.warning("没有对话数据可分析")
            return
        
        try:
            # 提取用户问题
            user_questions = []
            for conversation in self.conversations:
                for i, message in enumerate(conversation["messages"]):
                    if message["role"] == "user":
                        question = message["text"]
                        
                        # 尝试找到机器人的回答
                        answer = ""
                        if i + 1 < len(conversation["messages"]) and conversation["messages"][i + 1]["role"] == "bot":
                            answer = conversation["messages"][i + 1]["text"]
                        
                        user_questions.append({
                            "question": question,
                            "answer": answer,
                            "conversation_id": conversation["sender_id"]
                        })
            
            if not user_questions:
                logger.warning("没有找到用户问题")
                return
            
            # 使用TF-IDF向量对问题进行聚类
            questions = [q["question"] for q in user_questions]
            embeddings = vectorizer.fit_transform(questions).toarray()
            
            # 使用 DBSCAN 进行聚类
            clustering = DBSCAN(eps=0.3, min_samples=2).fit(embeddings)
            labels = clustering.labels_
            
            # 处理聚类结果
            clusters = {}
            for i, label in enumerate(labels):
                if label == -1:  # 噪声点
                    continue
                
                if label not in clusters:
                    clusters[label] = []
                
                clusters[label].append(user_questions[i])
            
            # 为每个聚类生成知识点
            for label, items in clusters.items():
                if len(items) < 2:  # 至少需要2个相似问题
                    continue
                
                # 选择最具代表性的问题和答案
                representative_item = max(items, key=lambda x: len(x["answer"]))
                question = representative_item["question"]
                answer = representative_item["answer"]
                
                # 使用 spaCy 提取关键词
                doc = nlp(question)
                keywords = [token.text for token in doc if token.pos_ in ("NOUN", "VERB", "ADJ") and not token.is_stop]
                
                # 创建知识点
                knowledge_item = {
                    "title": question[:50] + "..." if len(question) > 50 else question,
                    "content": f"## 问题\n\n{question}\n\n## 解答\n\n{answer}",
                    "keywords": keywords,
                    "source": "conversation",
                    "frequency": len(items),
                    "examples": [item["question"] for item in items[:5]]  # 最多5个例子
                }
                
                self.knowledge_items.append(knowledge_item)
            
            logger.info(f"从对话中识别了 {len(self.knowledge_items)} 个知识点")
            
        except Exception as e:
            logger.error(f"分析对话时出错: {str(e)}")
    
    def analyze_tickets(self):
        """分析工单，提取解决方案"""
        if not self.tickets:
            logger.warning("没有工单数据可分析")
            return
        
        try:
            # 处理每个工单
            for ticket in self.tickets:
                # 使用 spaCy 处理问题描述和解决方案
                description_doc = nlp(ticket["description"])
                resolution_doc = nlp(ticket["resolution"])
                
                # 提取关键词
                keywords = [token.text for token in description_doc 
                           if token.pos_ in ("NOUN", "VERB", "ADJ") and not token.is_stop]
                
                # 创建知识点
                knowledge_item = {
                    "title": ticket["subject"],
                    "content": f"## 问题描述\n\n{ticket['description']}\n\n## 解决方案\n\n{ticket['resolution']}",
                    "keywords": keywords,
                    "source": "ticket",
                    "ticket_number": ticket["number"],
                    "created": ticket["created"],
                    "updated": ticket["updated"]
                }
                
                self.knowledge_items.append(knowledge_item)
            
            logger.info(f"从工单中提取了 {len(self.tickets)} 个知识点")
            
        except Exception as e:
            logger.error(f"分析工单时出错: {str(e)}")
    
    def add_to_knowledge_base(self):
        """将提取的知识点添加到 BookStack 知识库"""
        if not self.knowledge_items:
            logger.warning("没有知识点可添加到知识库")
            return
        
        try:
            # 准备 API 请求头
            headers = {
                "Authorization": f"Token {BOOKSTACK_API_TOKEN}:{BOOKSTACK_API_SECRET}",
                "Content-Type": "application/json",
            }
            
            # 获取或创建知识库书籍
            books_url = f"{BOOKSTACK_URL}/api/books"
            books_response = requests.get(books_url, headers=headers)
            books_response.raise_for_status()
            
            books_data = books_response.json()
            ai_book = None
            
            # 查找名为 "AI 帮助台知识库" 的书籍
            for book in books_data.get("data", []):
                if book["name"] == "AI 帮助台知识库":
                    ai_book = book
                    break
            
            # 如果书籍不存在，则创建
            if not ai_book:
                create_book_url = f"{BOOKSTACK_URL}/api/books"
                book_data = {
                    "name": "AI 帮助台知识库",
                    "description": "由自动知识整理模块生成的知识库"
                }
                
                book_response = requests.post(
                    create_book_url,
                    headers=headers,
                    data=json.dumps(book_data)
                )
                book_response.raise_for_status()
                
                ai_book = book_response.json()
            
            book_id = ai_book["id"]
            
            # 获取或创建章节
            chapters_url = f"{BOOKSTACK_URL}/api/books/{book_id}/chapters"
            chapters_response = requests.get(chapters_url, headers=headers)
            chapters_response.raise_for_status()
            
            chapters_data = chapters_response.json()
            auto_chapter = None
            
            # 查找名为 "自动生成的知识" 的章节
            for chapter in chapters_data.get("data", []):
                if chapter["name"] == "自动生成的知识":
                    auto_chapter = chapter
                    break
            
            # 如果章节不存在，则创建
            if not auto_chapter:
                create_chapter_url = f"{BOOKSTACK_URL}/api/books/{book_id}/chapters"
                chapter_data = {
                    "name": "自动生成的知识",
                    "description": "由自动知识整理模块生成的知识点",
                    "book_id": book_id
                }
                
                chapter_response = requests.post(
                    create_chapter_url,
                    headers=headers,
                    data=json.dumps(chapter_data)
                )
                chapter_response.raise_for_status()
                
                auto_chapter = chapter_response.json()
            
            chapter_id = auto_chapter["id"]
            
            # 添加知识点作为页面
            pages_url = f"{BOOKSTACK_URL}/api/chapters/{chapter_id}/pages"
            
            # 获取现有页面以避免重复
            pages_response = requests.get(pages_url, headers=headers)
            pages_response.raise_for_status()
            
            existing_pages = pages_response.json().get("data", [])
            existing_titles = [page["name"] for page in existing_pages]
            
            # 添加新知识点
            added_count = 0
            for item in self.knowledge_items:
                # 检查标题是否已存在
                if item["title"] in existing_titles:
                    continue
                
                # 准备页面数据
                page_data = {
                    "name": item["title"],
                    "markdown": item["content"],
                    "tags": [{"name": kw} for kw in item["keywords"][:5]],  # 最多5个标签
                    "chapter_id": chapter_id
                }
                
                # 创建页面
                try:
                    page_response = requests.post(
                        pages_url,
                        headers=headers,
                        data=json.dumps(page_data)
                    )
                    page_response.raise_for_status()
                    added_count += 1
                except Exception as e:
                    logger.warning(f"添加知识点 '{item['title']}' 时出错: {str(e)}")
            
            logger.info(f"成功添加了 {added_count} 个新知识点到 BookStack")
            
        except Exception as e:
            logger.error(f"添加知识点到知识库时出错: {str(e)}")
    
    def run(self):
        """运行知识提取流程"""
        logger.info("开始知识提取流程")
        
        # 连接数据库
        if not self.connect_to_databases():
            logger.error("无法连接到数据库，终止流程")
            return
        
        # 提取数据
        self.extract_conversations(days=7)  # 提取最近7天的对话
        self.extract_tickets(days=30)  # 提取最近30天的已解决工单
        
        # 分析数据
        self.analyze_conversations()
        self.analyze_tickets()
        
        # 添加到知识库
        self.add_to_knowledge_base()
        
        logger.info("知识提取流程完成")


def main():
    """主函数"""
    extractor = KnowledgeExtractor()
    extractor.run()


if __name__ == "__main__":
    # 首次运行时等待其他服务启动
    logger.info("等待其他服务启动...")
    time.sleep(60)  # 等待60秒
    
    # 运行知识提取器
    while True:
        try:
            main()
        except Exception as e:
            logger.error(f"运行知识提取器时出错: {str(e)}")
        
        # 每天运行一次
        logger.info("等待下一次运行...")
        time.sleep(86400)  # 24小时 = 86400秒