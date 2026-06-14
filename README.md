# Mukundan-Textile

A full-stack modern e-commerce mobile application built with **Flutter** and **Supabase**.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.41+ installed
- A [Supabase](https://supabase.com) project
- Android Studio / VS Code with Flutter extensions

### Setup

1. **Clone the repository** and open in your IDE.

2. **Configure Supabase**: Open `lib/core/constants.dart` and replace:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

3. **Run the database migration**:
   - Open your Supabase project → SQL Editor
   - Copy and paste the contents of `supabase/supabase_schema.sql`
   - Click **Run** to create all tables, RLS policies, functions, triggers, and indexes

4. **Create Storage Buckets** in Supabase Dashboard → Storage:
   - `product-images` (Public)
   - `category-images` (Public)
   - `banner-images` (Public)
   - `avatars` (Private)

5. **Enable Realtime** for `orders` and `notifications` tables in Supabase Dashboard → Database → Replication.

6. **(Optional) Google OAuth**:
   - Create OAuth credentials in [Google Cloud Console](https://console.cloud.google.com)
   - Enable Google provider in Supabase → Authentication → Providers
   - Replace `webClientId` in `lib/data/repositories/auth_repository.dart`

7. **Install dependencies**:
   ```bash
   flutter pub get
   ```

8. **Run the app**:
   ```bash
   flutter run
   ```

### Creating an Admin User

After signing up, update the user's role in Supabase:
```sql
UPDATE profiles SET role = 'admin' WHERE email = 'your-email@example.com';
```

## 📁 Project Structure

```
lib/
├── core/           # Constants, theme, router, utils
├── data/           # Models & repositories (Supabase services)
├── features/       # Feature-based modules
│   ├── auth/       # Login, signup, profile, addresses
│   ├── customer/   # Bottom navigation shell
│   ├── home/       # Home screen with banners, categories
│   ├── product/    # Product list, detail, search
│   ├── cart/       # Cart, checkout, order success
│   ├── orders/     # Order list, order detail
│   ├── wishlist/   # Wishlist
│   ├── notifications/ # In-app notifications
│   └── admin/      # Admin dashboard & management screens
└── shared/         # Reusable widgets

supabase/
└── supabase_schema.sql  # Complete database migration
```

## 🎨 Design

- **Theme**: Material 3 with custom deep indigo + violet palette
- **Typography**: Inter (body) + Outfit (headings) via Google Fonts
- **Dark Mode**: Full dark mode support (follows system)
- **State Management**: flutter_bloc (Cubit pattern)
- **Navigation**: go_router with auth guards

## 🔐 Security

- Row Level Security (RLS) on all tables
- Users can only access their own data
- Admin-only routes protected by role checks
- Banned users are automatically signed out

## 📦 Key Packages

| Package | Purpose |
|---------|---------|
| supabase_flutter | Backend (Auth, DB, Storage, Realtime) |
| flutter_bloc | State management |
| go_router | Navigation & routing |
| cached_network_image | Image caching |
| carousel_slider | Home banner carousel |
| fl_chart | Admin dashboard charts |
| shimmer | Loading skeletons |
| google_fonts | Custom typography |
| image_picker | Image uploads |

## 📝 License

This project is for educational/personal use.
# Mukundan-Textiles
