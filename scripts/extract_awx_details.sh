#!/bin/bash
num_participants=$1
output_file="awx_details.json"

echo "{" > $output_file
for i in $(seq 0 $(($num_participants - 1))); do
  details_file="/tmp/awx_access_details_$i.txt"
  awx_url=$(grep "AWX URL" $details_file | awk '{print $3}')
  awx_admin_password=$(grep "AWX Admin Password" $details_file | awk '{print $4}')
  echo "  \"awx_url_$i\": \"$awx_url\"," >> $output_file
  echo "  \"awx_admin_password_$i\": \"$awx_admin_password\"" >> $output_file
  if [ $i -lt $(($num_participants - 1)) ]; then
    echo "  ," >> $output_file
  fi
done
echo "}" >> $output_file

# Ensure the last comma is removed and closing brace is added correctly
sed -i '$ s/,$//' $output_file
echo "}" >> $output_file

cat $output_file