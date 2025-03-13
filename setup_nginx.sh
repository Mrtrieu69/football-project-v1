#!/bin/bash

# Hỏi người dùng nhập IP address
read -p "Nhập IP address (ví dụ: 213.180.0.36): " IP_ADDRESS

# Kiểm tra xem IP address có hợp lệ không (đơn giản)
if [[ ! $IP_ADDRESS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "IP address không hợp lệ. Vui lòng nhập lại."
    exit 1
fi

# Tên file cấu hình
CONFIG_FILE="flask_app"
# Đường dẫn đến thư mục sites-available và sites-enabled
SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"
# Nội dung file cấu hình với IP address được thay thế
CONFIG_CONTENT='
server {
    listen 80;
    server_name '"$IP_ADDRESS"';  # Sử dụng IP address từ người dùng

    # Phục vụ Vue.js frontend
    location / {
        proxy_pass http://localhost:5173;  # Proxy đến Vue.js dev server
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Proxy các yêu cầu API đến Flask backend
    location /api/ {
        proxy_pass http://localhost:5000/api/;  # Proxy đến Flask backend
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Phục vụ các tệp video từ Flask backend
    location /backend/ {
        proxy_pass http://localhost:5000/backend/;  # Proxy đến Flask backend
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
'

# Kiểm tra và cài đặt Nginx nếu chưa có
if ! command -v nginx &> /dev/null; then
    echo "Nginx chưa được cài đặt. Đang tiến hành cài đặt..."
    sudo apt install -y nginx
    echo "Nginx đã được cài đặt thành công."
else
    echo "Nginx đã được cài đặt."
fi

# Tạo file cấu hình trong thư mục sites-available
echo "Tạo file cấu hình Nginx..."
sudo bash -c "echo '$CONFIG_CONTENT' > $SITES_AVAILABLE/$CONFIG_FILE"

# Tạo symbolic link đến thư mục sites-enabled
if [ ! -f "$SITES_ENABLED/$CONFIG_FILE" ]; then
    echo "Tạo symbolic link đến thư mục sites-enabled..."
    sudo ln -s "$SITES_AVAILABLE/$CONFIG_FILE" "$SITES_ENABLED/$CONFIG_FILE"
else
    echo "Symbolic link đã tồn tại."
fi

# Kiểm tra cú pháp cấu hình Nginx
echo "Kiểm tra cú pháp cấu hình Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "Cú pháp cấu hình hợp lệ. Khởi động lại Nginx..."
    sudo systemctl restart nginx
    echo "Nginx đã được khởi động lại và cấu hình đã được áp dụng."
else
    echo "Lỗi trong cấu hình Nginx. Vui lòng kiểm tra lại file cấu hình."
fi