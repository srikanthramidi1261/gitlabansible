INSTANCE_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`

#IP=aws ec2 describe-instances --filters Name=instance-id,Values=$INSTANCE_ID | jq ".Reservations[0].Instances[0].NetworkInterfaces[0].PrivateIpAddress"
IP=`aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=instance-id,Values=$INSTANCE_ID" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text`

USER='aws secretsmanager get-secret-value --secret-id gitlab-token | jq ".SecretString|fromjson" | grep user | awk '{print $2}' | tr -d \" | tr -d \,'
PATOKEN='aws secretsmanager get-secret-value --secret-id gitlab-token | jq ".SecretString|fromjson" | grep pat | awk '{print $2}' | tr -d \" | tr -d \,'
PASSWORD='aws secretsmanager get-secret-value --secret-id gitlab-token | jq ".SecretString|fromjson" | grep pass | awk '{print $2}' | tr -d \" | tr -d \,'

sleep 3m

sudo docker exec -it gitlab gitlab-rails runner "u = User.new(username: '$USER', email: 'runner@example.com', name: 'test_user', password: '$PASSWORD', password_confirmation: '$PASSWORD'); u.admin = true; u.save!"

sudo docker exec -it gitlab gitlab-rails runner "token = User.find_by_username('$USER').personal_access_tokens.create(scopes: ['read_user', 'read_repository', 'api', 'admin_mode', 'read_api', 'read_repository', 'write_repository'], name: 'Automation token', expires_at: 365.days.from_now); token.set_token('$PATOKEN'); token.save!"

sudo docker exec -it gitlab curl -sX POST http://$IP/api/v4/user/runners --data runner_type=instance_type --data "user_id=6" --data "description=software-eng-docker-builds-runner" --data "tag_list=test" --header "PRIVATE-TOKEN: $PATOKEN" > /tmp/abc

#docker exec -it gitlab gitlab-rails runner "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token" > /tmp/abc
