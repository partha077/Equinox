import csv
import os

def name_matches(first_name, last_name, owner_names):
    """Check if the first name or last name matches any name in the OWNER NAME field."""
    for owner_name in owner_names:
        owner_parts = owner_name.strip().lower().split()
        if first_name in owner_parts or last_name in owner_parts:
            return True
    return False

def process_csv(indian_names_file, input_csv_file, output_folder, num_chars_to_compare):
    """Process the CSV to match names and compare fields."""
    # Load names from the text file
    try:
        with open(indian_names_file, 'r') as names_file:
            search_names = [name.strip().lower() for name in names_file.readlines()]
    except FileNotFoundError:
        print(f"Error: File '{indian_names_file}' not found.")
        return

    matching_rows = []

    # Search for matching rows in the input CSV
    try:
        with open(input_csv_file, 'r', newline='') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if "OWNER NAME" in row:
                    owner_names = row["OWNER NAME"].split(",")
                    for name in search_names:
                        first_name, *last_name_parts = name.split()
                        last_name = last_name_parts[-1] if last_name_parts else ""
                        if name_matches(first_name, last_name, owner_names):
                            matching_rows.append(row)
                            break
    except FileNotFoundError:
        print(f"Error: File '{input_csv_file}' not found.")
        return

    if not matching_rows:
        print("No matching rows found in Step 1 (name matching).")
        return

    # Compare fields for matching rows
    final_rows = []
    for row in matching_rows:
        if "OWNER ADDRESS" in row and "SITUS ADDRESS" in row:
            owner_address = row["OWNER ADDRESS"].strip().lower()
            situs_address = row["SITUS ADDRESS"].strip().lower()

            # Compare first num_chars_to_compare characters
            if len(owner_address) >= num_chars_to_compare and len(situs_address) >= num_chars_to_compare:
                if owner_address[:num_chars_to_compare] == situs_address[:num_chars_to_compare]:
                    final_rows.append(row)

    if not final_rows:
        print("No matching rows found in Step 2 (field comparison).")
        return

    # Save final result to the output folder
    os.makedirs(output_folder, exist_ok=True)
    output_csv_file = os.path.join(output_folder, 'final_output.csv')

    try:
        with open(output_csv_file, 'w', newline='') as output_csv:
            fieldnames = final_rows[0].keys()
            writer = csv.DictWriter(output_csv, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(final_rows)
        print(f"Final matching rows have been saved to {output_csv_file}")
    except Exception as e:
        print(f"Error while writing the final output: {e}")

if __name__ == "__main__":
    # Declare all input variables here
    indian_names_file = 'indian_names.txt'  # Path to the text file with names
    input_csv_file = 'Search Result8.csv'  # Path to the input CSV file
    output_folder = 'final_result'  # Folder to save the output
    num_chars_to_compare = 3  # Number of characters to compare in addresses

    # Call the processing function
    process_csv(indian_names_file, input_csv_file, output_folder, num_chars_to_compare)
