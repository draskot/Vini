
# Check if the script received an argument
if [ $# -eq 0 ]; then
  echo "Usage: $0 <required_input>"
  exit 1
fi

# Define the required input from the script argument
required_input="$1"

# Prompt the user and read the input in a loop
while true; do
  read -p "Enter '$required_input' to proceed: " user_input
  echo  # Move to a new line

  # Check if the input matches the required input
  if [ "$user_input" == "$required_input" ]; then
     break  # Exit the loop if the correct input is provided
  else
     echo "Invalid input. Enter '$required_input' to proceed."
  fi
done


