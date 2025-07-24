-- Create osTicket database and user
CREATE DATABASE IF NOT EXISTS osticket;
CREATE USER IF NOT EXISTS 'osticket'@'%' IDENTIFIED BY 'osticket_password';
GRANT ALL PRIVILEGES ON osticket.* TO 'osticket'@'%';
FLUSH PRIVILEGES;

-- Use osTicket database
USE osticket;

-- Create basic tables for osTicket (simplified version)
CREATE TABLE IF NOT EXISTS ost_ticket (
    ticket_id int(11) NOT NULL AUTO_INCREMENT,
    number varchar(20) NOT NULL,
    user_id int(11) NOT NULL DEFAULT 0,
    status_id int(11) NOT NULL DEFAULT 1,
    dept_id int(11) NOT NULL DEFAULT 1,
    priority_id int(11) NOT NULL DEFAULT 2,
    topic_id int(11) NOT NULL DEFAULT 1,
    staff_id int(11) NOT NULL DEFAULT 0,
    team_id int(11) NOT NULL DEFAULT 0,
    sla_id int(11) NOT NULL DEFAULT 0,
    source enum('Web','Email','Phone','API','Other') NOT NULL DEFAULT 'Web',
    ip_address varchar(45) NOT NULL DEFAULT '',
    created datetime NOT NULL,
    updated datetime NOT NULL,
    duedate datetime DEFAULT NULL,
    closed datetime DEFAULT NULL,
    reopened datetime DEFAULT NULL,
    isanswered tinyint(1) NOT NULL DEFAULT 0,
    isoverdue tinyint(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (ticket_id),
    UNIQUE KEY number (number),
    KEY user_id (user_id),
    KEY status_id (status_id),
    KEY dept_id (dept_id),
    KEY staff_id (staff_id),
    KEY team_id (team_id),
    KEY created (created),
    KEY closed (closed),
    KEY duedate (duedate)
);

CREATE TABLE IF NOT EXISTS ost_thread (
    id int(11) NOT NULL AUTO_INCREMENT,
    object_id int(11) NOT NULL DEFAULT 0,
    object_type char(1) NOT NULL,
    extra text,
    created datetime NOT NULL,
    updated datetime NOT NULL,
    PRIMARY KEY (id),
    KEY object_id (object_id),
    KEY object_type (object_type)
);

CREATE TABLE IF NOT EXISTS ost_thread_entry (
    id int(11) NOT NULL AUTO_INCREMENT,
    thread_id int(11) NOT NULL DEFAULT 0,
    staff_id int(11) NOT NULL DEFAULT 0,
    user_id int(11) NOT NULL DEFAULT 0,
    type char(1) NOT NULL DEFAULT 'M',
    flags int(11) NOT NULL DEFAULT 0,
    poster varchar(128) NOT NULL DEFAULT '',
    editor int(11) NOT NULL DEFAULT 0,
    source varchar(32) NOT NULL DEFAULT '',
    title varchar(255),
    body text,
    format varchar(16) NOT NULL DEFAULT 'html',
    ip_address varchar(45) NOT NULL DEFAULT '',
    extra text,
    created datetime NOT NULL,
    updated datetime NOT NULL,
    PRIMARY KEY (id),
    KEY thread_id (thread_id),
    KEY staff_id (staff_id),
    KEY type (type)
);

-- Insert sample data
INSERT INTO ost_ticket (number, user_id, status_id, dept_id, created, updated) VALUES
('100001', 1, 3, 1, '2024-01-01 10:00:00', '2024-01-01 15:00:00'),
('100002', 2, 3, 1, '2024-01-02 09:00:00', '2024-01-02 14:00:00'),
('100003', 3, 1, 1, '2024-01-03 11:00:00', '2024-01-03 11:00:00');

INSERT INTO ost_thread (object_id, object_type, created, updated) VALUES
(1, 'T', '2024-01-01 10:00:00', '2024-01-01 15:00:00'),
(2, 'T', '2024-01-02 09:00:00', '2024-01-02 14:00:00'),
(3, 'T', '2024-01-03 11:00:00', '2024-01-03 11:00:00');

INSERT INTO ost_thread_entry (thread_id, user_id, type, poster, title, body, created, updated) VALUES
(1, 1, 'M', 'user1@example.com', '登录问题', '我无法登录系统，提示密码错误', '2024-01-01 10:00:00', '2024-01-01 10:00:00'),
(1, 0, 'R', 'support@example.com', 'Re: 登录问题', '请尝试重置密码，或检查用户名是否正确', '2024-01-01 15:00:00', '2024-01-01 15:00:00'),
(2, 2, 'M', 'user2@example.com', '系统运行缓慢', '系统响应很慢，页面加载时间过长', '2024-01-02 09:00:00', '2024-01-02 09:00:00'),
(2, 0, 'R', 'support@example.com', 'Re: 系统运行缓慢', '我们已经优化了服务器性能，现在应该正常了', '2024-01-02 14:00:00', '2024-01-02 14:00:00'),
(3, 3, 'M', 'user3@example.com', '功能请求', '希望能添加导出功能', '2024-01-03 11:00:00', '2024-01-03 11:00:00');