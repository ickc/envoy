#!/bin/bash

# Check if filename argument is provided
if [[ $# -ne 1 ]]; then
    echo 'Usage: compile.sh FILENAME' >&2
    exit 1
fi

FILENAME="$1"

# Check if the input file exists
if [[ ! -f ${FILENAME} ]]; then
    echo "Error: File '${FILENAME}' not found" >&2
    exit 1
fi

# Simple stack to track processed files (prevent infinite recursion)
PROCESSING_STACK=""

# Function to check if a file is already being processed
is_file_processed() {
    local file_path="$1"
    # Normalize the path to avoid issues
    local normalized_path
    if command -v realpath > /dev/null 2>&1; then
        normalized_path="$(realpath "${file_path}" 2> /dev/null)"
    else
        # Fallback for systems without realpath
        normalized_path="$(cd "$(dirname "${file_path}")" 2> /dev/null && printf '%s/%s' "$(pwd)" "$(basename "${file_path}")")"
    fi

    # Check if this path is in our processing stack
    case ":${PROCESSING_STACK}:" in
        *":${normalized_path}:"*) return 0 ;;
        *) return 1 ;;
    esac
}

# Function to push a file onto the processing stack
push_file() {
    local file_path="$1"
    local normalized_path
    if command -v realpath > /dev/null 2>&1; then
        normalized_path="$(realpath "${file_path}" 2> /dev/null)"
    else
        normalized_path="$(cd "$(dirname "${file_path}")" 2> /dev/null && printf '%s/%s' "$(pwd)" "$(basename "${file_path}")")"
    fi
    PROCESSING_STACK="${PROCESSING_STACK}:${normalized_path}"
}

# Function to pop a file from the processing stack
pop_file() {
    local file_path="$1"
    local normalized_path
    if command -v realpath > /dev/null 2>&1; then
        normalized_path="$(realpath "${file_path}" 2> /dev/null)"
    else
        normalized_path="$(cd "$(dirname "${file_path}")" 2> /dev/null && printf '%s/%s' "$(pwd)" "$(basename "${file_path}")")"
    fi
    # Remove the path from the stack
    PROCESSING_STACK="${PROCESSING_STACK//:${normalized_path}/}"
}

# Function to recursively process a file
# Arguments: file_path base_directory
process_file() {
    local file_path="$1"
    local base_dir="$2"

    # Check for circular dependencies
    if is_file_processed "${file_path}"; then
        echo "Warning: Circular dependency detected for '${file_path}', skipping" >&2
        return 0
    fi

    # Mark this file as being processed
    push_file "${file_path}"

    # Process the file line by line
    while IFS= read -r line || [[ -n ${line} ]]; do
        # Check if line matches the pattern ^source FILENAME$
        if [[ ${line} =~ ^source\ (.+)$ ]]; then
            # Extract the filepath
            local source_path="${BASH_REMATCH[1]}"

            # Handle absolute vs relative paths
            local full_path
            if [[ ${source_path} =~ ^/ ]]; then
                # Absolute path
                full_path="${source_path}"
            else
                # Relative path - resolve relative to the current file's directory
                full_path="${base_dir}/${source_path}"
            fi

            # Check if the referenced file exists
            if [[ -f ${full_path} ]]; then
                # Get the directory of the sourced file for nested relative paths
                local source_dir
                source_dir="$(dirname "${full_path}")"

                # Recursively process the sourced file
                process_file "${full_path}" "${source_dir}"
            else
                echo "Error: Referenced file '${full_path}' not found" >&2
                exit 1
            fi
        else
            # Print the line as-is
            echo "${line}"
        fi
    done < "${file_path}"

    # Unmark this file after processing
    pop_file "${file_path}"
}

# Get the directory of the input file for relative path resolution
BASEDIR="$(dirname "${FILENAME}")"

process_file "${FILENAME}" "${BASEDIR}"
