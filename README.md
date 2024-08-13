# MediaUploaderApp

MediaUploaderApp is a web application designed for people in a specific circle—such as friends, family, or colleagues—to upload photos and videos directly to an external hard drive. The application creates a dedicated directory for each user within the `MediaUploader` folder on the external drive, allowing users to upload their media files. Additionally, users can view files uploaded by other users on the main page.

## Features

- **User Registration and Login**: Users can create accounts and log into the application.
- **Folder Management**: Users can create, rename, and delete folders.
- **File Upload**: Users can upload images and video files.
- **Media Viewing**: Users can browse uploaded files and watch videos in a separate tab.
- **EXIF Information**: View EXIF data for images, including capture date, aperture, exposure time, and ISO.
- **Disk Space Monitoring**: Display available and used disk space on the device where files are uploaded.

## Installation

Follow these steps to run a local copy of the project:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/MediaUploaderApp.git
   cd MediaUploaderApp
  ```

2. **Install dependencies:
```bash
  bundle install
```

3. **Set up the database:
```bash
  rails db:migrate
```

4. **Start the server:
```bash
  rails server
```

5. **Access the application:
```bash
The application will be available at http://localhost:3000.
```
