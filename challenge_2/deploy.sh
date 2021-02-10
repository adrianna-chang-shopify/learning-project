echo 'Deploying to production!'
echo '🚀 Pushing changes'
git push production main
echo '♻️ Restarting service'
ssh ubuntu@ec2-174-129-49-169.compute-1.amazonaws.com systemctl --user restart http
echo '🔍 Fetching status'
ssh ubuntu@ec2-174-129-49-169.compute-1.amazonaws.com systemctl --user status http