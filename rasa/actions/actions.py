from typing import Any, Text, Dict, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import SlotSet
import requests
import os

class ActionSearchKnowledge(Action):
    def name(self) -> Text:
        return "action_search_knowledge"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        user_message = tracker.latest_message.get('text')
        
        # 这里可以集成BookStack API来搜索知识库
        # 暂时返回一个默认回复
        
        dispatcher.utter_message(text=f"我正在为您搜索相关信息：{user_message}")
        
        return []

class ActionCreateTicket(Action):
    def name(self) -> Text:
        return "action_create_ticket"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        user_message = tracker.latest_message.get('text')
        problem_type = tracker.get_slot('problem_type')
        urgency = tracker.get_slot('urgency')
        
        # 这里可以集成osTicket API来创建工单
        # 暂时返回一个确认消息
        
        dispatcher.utter_message(
            text=f"我已经为您创建了一个工单。问题类型：{problem_type}，紧急程度：{urgency}。我们会尽快处理您的问题。"
        )
        
        return []