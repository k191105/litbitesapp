import os

# configure these
root_dir = "/Users/krishivsinghal/Desktop/quote/literaturebites/lib"
output_file = "all_code.txt"
extensions = {".py", ".js", ".dart", ".java", ".cpp", ".ts"}  # adjust as needed

with open(output_file, "w", encoding="utf-8") as outfile:
    for dirpath, _, filenames in os.walk(root_dir):
        for fname in filenames:
            if any(fname.endswith(ext) for ext in extensions):
                full_path = os.path.join(dirpath, fname)
                rel_path = os.path.relpath(full_path, root_dir)

                outfile.write(f"\n\n===== {rel_path} =====\n\n")
                with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                    outfile.write(f.read())