#!/bin/bash

# Ask the user for the website URL or domain
read -p "Enter the website URL or domain: " website_input

# Normalize the input: Add "https://" if the input is just a domain without protocol
if [[ ! $website_input =~ ^https?:// ]]; then
    website_url="https://$website_input"
else
    website_url="$website_input"
fi

# Extract Domain name from website url
domain_name="${website_url#*://}"  # Remove the protocol
domain_name="${domain_name%%/*}"     # Remove any path or query parameters

# Inform the user of the normalized URL being used
echo "Normalized URL being used: $website_url"

# Create an output directory if it doesn't exist
output_dir="output"
mkdir -p "$output_dir/$domain_name"

# Step 1: Run katana with passive sources and save output to a unified file (output/output.txt)
echo "Running katana with passive sources (waybackarchive, commoncrawl, alienvault)..."
echo "$website_url" | katana -ps -pss waybackarchive,commoncrawl,alienvault -f qurl | uro > "$output_dir/$domain_name/output.txt"

# Step 2: Run katana actively with depth 5 and append results to output/output.txt
echo "Running katana actively with depth 5..."
katana -u "$website_url" -d 5 -f qurl | uro | anew "$output_dir/$domain_name/output.txt"

# Step 3: Filter output/output.txt for different vulnerabilities

# XSS
echo "Filtering URLs for potential XSS endpoints..."
cat "$output_dir/$domain_name/output.txt" | Gxss | kxss | grep -oP '^URL: \K\S+' | sed 's/=.*/=/' | sort -u > "$output_dir/$domain_name/xss_output.txt"
echo "Extracting final filtered XSS URLs to $output_dir/$domain_name/xss_output.txt..."

# Open Redirect
echo "Filtering URLs for potential Open Redirect endpoints..."
cat "$output_dir/$domain_name/output.txt" | gf or | sed 's/=.*/=/' | sort -u > "$output_dir/$domain_name/open_redirect_output.txt"
echo "Extracting final filtered Open Redirect URLs to $output_dir/$domain_name/open_redirect_output.txt..."

# LFI
echo "Filtering URLs for potential LFI endpoints..."
cat "$output_dir/$domain_name/output.txt" | gf lfi | sed 's/=.*/=/' | sort -u > "$output_dir/$domain_name/lfi_output.txt"
echo "Extracting final filtered LFI URLs to $output_dir/$domain_name/lfi_output.txt..."

# SQLi
echo "Filtering URLs for potential SQLi endpoints..."
cat "$output_dir/$domain_name/output.txt" | gf sqli | sed 's/=.*/=/' | sort -u > "$output_dir/$domain_name/sqli_output.txt"
echo "Extracting final filtered SQLi URLs to $output_dir/$domain_name/sqli_output.txt..."

# Remove the intermediate file output/output.txt
rm "$output_dir/$domain_name/output.txt"

# Notify the user that all tasks are complete
echo "Filtered URLs have been saved to the respective output files in the 'output/$domain_name' directory:"
echo "  - XSS: $output_dir/$domain_name/xss_output.txt"
echo "  - Open Redirect: $output_dir/$domain_name/open_redirect_output.txt"
echo "  - LFI: $output_dir/$domain_name/lfi_output.txt"
echo "  - SQLi: $output_dir/$domain_name/sqli_output.txt"
