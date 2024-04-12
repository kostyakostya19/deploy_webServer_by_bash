# Вопрос/Ответ
1. Ansible. Удобная структура
2. Ansible + Terraform. Потому что не потребуется ручного запуска 

# Протестированно на Rocky Linux 9

# prepare before start
- make the config.sh
```
touch ./config.sh

cat <<EOF >> ./config.sh
TOKEN=" "
CHAT_ID=" "
EOF
```
# how to start
```
sudo bash main.sh
```