#!/bin/bash

# Script để cài đặt và cấu hình Nginx trên server
# Sử dụng tham số dòng lệnh để truyền giá trị domain

# Kiểm tra xem có tham số domain được cung cấp không
if [ -z "$1" ]; then
    echo "Vui lòng cung cấp domain hoặc IP (ví dụ: 127.0.0.1)."
    echo "Cách sử dụng: $0 <domain_or_ip>"
    exit 1
fi

DOMAIN_OR_IP=$1

# Cài đặt Nginx
echo "Cài đặt Nginx..."
sudo apt-get install nginx -y

# Cấu hình Nginx
echo "Cấu hình Nginx..."

# Tạo file cấu hình cho ứng dụng
CONFIG_FILE="/etc/nginx/sites-available/flask_app"
CONFIG_LINK="/etc/nginx/sites-enabled/flask_app"

# Nội dung cấu hình Nginx
cat <<EOL | sudo tee $CONFIG_FILE > /dev/null
server {
    listen 80;
    server_name $DOMAIN_OR_IP;  # Thay bằng domain của bạn

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
EOL

# Tạo symbolic link để kích hoạt cấu hình
echo "Kích hoạt cấu hình Nginx..."
sudo ln -sf $CONFIG_FILE $CONFIG_LINK

# Xóa cấu hình mặc định (nếu có)
sudo rm -f /etc/nginx/sites-enabled/default

# Kiểm tra cấu hình Nginx
echo "Kiểm tra cấu hình Nginx..."
sudo nginx -t

# Khởi động lại Nginx để áp dụng cấu hình
echo "Khởi động lại Nginx..."
sudo systemctl restart nginx

# Kích hoạt Nginx để khởi động cùng hệ thống
echo "Kích hoạt Nginx để khởi động cùng hệ thống..."
sudo systemctl enable nginx

echo "Cài đặt và cấu hình Nginx hoàn tất!"