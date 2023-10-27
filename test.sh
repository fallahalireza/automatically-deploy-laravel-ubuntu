# اجرای دستور ifconfig برای دریافت آدرس IPv4
ipv4_address=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

# نمایش آدرس IPv4
echo "آدرس IPv4 سرور: $ipv4_address"


# اجرای دستور ip برای دریافت آدرس IPv4
ipv4_address2=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# نمایش آدرس IPv4
echo "آدرس IPv4 سرور: $ipv4_address2"
