# 🧵 ThreadSocial API Documentation

Dokumentasi API untuk aplikasi **ThreadSocial**. Backend menggunakan PHP dengan database MySQL dan autentikasi JWT.

## 📋 Informasi Dasar
- **Base URL:** `https://naufal.bersama.cloud/api`
- **Content-Type:** `application/json`
- **Autentikasi:** Bearer Token (JWT) pada header `Authorization`

---

## 🔐 Auth Endpoints

### 1. Register
Mendaftarkan pengguna baru dan mengembalikan JWT token.
- **Endpoint:** `POST /auth/register.php`
- **Body:**
```json
{
  "username": "naufal",
  "email": "naufal@example.com",
  "password": "password123",
  "full_name": "Naufal",
  "bio": "Flutter Developer",
  "profile_image": "unique_filename.jpg"
}

{
  "email": "[EMAIL_ADDRESS]",
  "password": "password123"
}
- **Endpoint:** `GET /threads/feed.php`
- **Headers:** `Authorization: Bearer <token>` (Opsional, untuk status `is_liked`)
- **Query Params:**
  - `limit`: (int) Jumlah data (default: 20)
  - `offset`: (int) Index awal (default: 0)
  - `user_id`: (int, opsional) Filter thread berdasarkan User ID

### 2. Create Thread
Membuat postingan thread baru.
- **Endpoint:** `POST /threads/create.php`
- **Headers:** `Authorization: Bearer <token>` (Wajib)
- **Body:**
```json
{
  "content": "Halo dunia!",
  "image": "image_filename.jpg"
}
```

### 3. Like/Unlike Thread
Menyukai atau membatalkan suka pada thread (Toggle).
- **Endpoint:** `POST /threads/like.php?id={thread_id}`
- **Headers:** `Authorization: Bearer <token>` (Wajib)

### 4. Get Comments
Mengambil semua komentar dalam suatu thread.
- **Endpoint:** `GET /threads/comments.php?id={thread_id}`

### 5. Post Comment
Menambahkan komentar baru ke thread.
- **Endpoint:** `POST /threads/comment.php?id={thread_id}`
- **Headers:** `Authorization: Bearer <token>` (Wajib)
- **Body:**
```json
{
  "content": "Komentar yang sangat menarik!"
}
```

---

## 👤 Users & Social Endpoints

### 1. Get User Profile
Mengambil detail profil pengguna, jumlah follower, dan status follow.
- **Endpoint:** `GET /users/profile.php?id={user_id}`
- **Headers:** `Authorization: Bearer <token>` (Opsional, untuk status `is_following`)

### 2. Update Profile
Mengupdate informasi profil pengguna yang sedang login.
- **Endpoint:** `PUT /users/profile.php?id={user_id}`
- **Headers:** `Authorization: Bearer <token>` (Wajib)
- **Body:**
```json
{
  "full_name": "Nama Baru",
  "bio": "Bio baru saya",
  "profile_image": "new_photo.jpg"
}
```

### 3. Follow/Unfollow User
Mengikuti atau berhenti mengikuti pengguna lain (Toggle).
- **Endpoint:** `POST /users/follow.php?id={target_user_id}`
- **Headers:** `Authorization: Bearer <token>` (Wajib)

---

## 🖼️ Upload Endpoints

### 1. Upload Image
Mengunggah file gambar ke server.
- **Endpoint:** `POST /upload/image.php`
- **Body (Multipart/Form-Data):**
  - `image`: (File) File gambar
  - `type`: (String) 'profiles' atau 'threads'
- **Response:**
```json
{
  "message": "Image uploaded successfully",
  "filename": "65ab...jpg",
  "url": "api/uploads/threads/65ab...jpg"
}
```

---

## 📁 Struktur Direktori Image
- Profile Photos: `/api/uploads/profiles/`
- Thread Images: `/api/uploads/threads/`
