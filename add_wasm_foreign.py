#!/usr/bin/env python3
"""
Script to add wasm-compatible foreign blocks to Odin bindings.

Wasm cannot use named foreign imports (foreign lib), so this script
duplicates foreign blocks as anonymous imports (foreign _) wrapped
in platform when conditions.
"""

import sys
import re
from pathlib import Path


def process_file(content: str) -> str:
    """
    Process Odin file content to add wasm-compatible foreign blocks.

    Finds foreign blocks like:
        @(...)
        foreign lib {
            proc1 :: proc(...) ---
            proc2 :: proc(...) ---
        }

    And wraps them like:
        when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
            @(...)
            foreign _ {
                proc1 :: proc(...) ---
                proc2 :: proc(...) ---
            }
        } else {
            @(...)
            foreign lib {
                proc1 :: proc(...) ---
                proc2 :: proc(...) ---
            }
        }
    """

    # Pattern to match foreign blocks with their attributes
    # Captures: (attributes)(foreign lib_name)(block_content)
    pattern = r'(@\([^\)]*\)\s*\n)?(foreign\s+(\w+)\s*\{[^}]*\})'

    def replace_foreign(match):
        attributes = match.group(1) if match.group(1) else ""
        full_block = match.group(2)
        lib_name = match.group(3)

        # Skip if already wrapped in when condition or if using foreign _
        if lib_name == "_":
            return match.group(0)

        # Extract the content between the braces
        block_match = re.search(r'foreign\s+\w+\s*(\{.*\})', full_block, re.DOTALL)
        if not block_match:
            return match.group(0)

        block_content = block_match.group(1)

        # Create wasm version with foreign _
        wasm_block = f"{attributes}foreign _ {block_content}"

        # Create original version
        original_block = f"{attributes}foreign {lib_name} {block_content}"

        # Wrap in when condition
        result = (
            f"when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {{\n"
            f"    {wasm_block.replace(chr(10), chr(10) + '    ').rstrip()}\n"
            f"}} else {{\n"
            f"    {original_block.replace(chr(10), chr(10) + '    ').rstrip()}\n"
            f"}}"
        )

        return result

    # Check if file already has wasm when conditions
    if 'when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32' in content:
        print("  File already has wasm conditions, skipping...", file=sys.stderr)
        return content

    # Find and replace foreign blocks
    result = re.sub(pattern, replace_foreign, content, flags=re.MULTILINE | re.DOTALL)

    return result


def main():
    if len(sys.argv) < 2:
        print("Usage: add_wasm_foreign.py <file.odin> [output.odin]")
        print("If output is not specified, will write to stdout")
        sys.exit(1)

    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else None

    if not input_file.exists():
        print(f"Error: {input_file} not found", file=sys.stderr)
        sys.exit(1)

    print(f"Processing {input_file}...", file=sys.stderr)

    content = input_file.read_text()
    result = process_file(content)

    if output_file:
        output_file.write_text(result)
        print(f"Wrote to {output_file}", file=sys.stderr)
    else:
        print(result)


if __name__ == "__main__":
    main()
