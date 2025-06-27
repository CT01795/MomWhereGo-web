import os
import dropbox

DROPBOX_ACCESS_TOKEN = os.environ['DROPBOX_ACCESS_TOKEN']
TARGET_FOLDER = '/MomWhereGo'  # Dropbox 中的目標資料夾
LOCAL_FOLDER = 'dropbox_files'  # 同步到 repo 的資料夾

dbx = dropbox.Dropbox(DROPBOX_ACCESS_TOKEN)

def download_files(path, local_path):
    try:
        os.makedirs(local_path, exist_ok=True)
        res = dbx.files_list_folder(path)
        for entry in res.entries:
            if isinstance(entry, dropbox.files.FileMetadata):
                local_file_path = os.path.join(local_path, entry.name)
                print(f"Downloading {entry.path_lower} to {local_file_path}")
                metadata, res = dbx.files_download(entry.path_lower)
                with open(local_file_path, 'wb') as f:
                    f.write(res.content)
            elif isinstance(entry, dropbox.files.FolderMetadata):
                download_files(entry.path_lower, os.path.join(local_path, entry.name))
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    download_files(TARGET_FOLDER, LOCAL_FOLDER)
