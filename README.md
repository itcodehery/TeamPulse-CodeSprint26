# Hunger N Waste - Team Pulse

**Team Pulse** | **CHRIST (Deemed to be University), Central Campus**
**Problem Statement ID:** CS01SW

## 📖 Overview

**Hunger N Waste** is a digital platform designed to bridge the gap between surplus food sources and NGOs. By leveraging real-time location services, the application connects donors with verified organizations to facilitate the efficient redistribution of food, effectively reducing food waste while aiding hunger relief efforts.

## 🚀 Problem & Solution

### The Problem
Food waste and hunger are two simultaneous global crises. While massive amounts of food are discarded daily, many communities struggle with food insecurity. The lack of a streamlined logistics network makes it difficult to transfer surplus food to those in need quickly and safely.

### Our Solution
We propose a mobile application that:
- **Connects** donors (Caterers, Event Organizers, Individuals) with nearby verified NGOs.
- **Facilitates** real-time pickup requests for surplus food.
- **Assigns** riders for collection and delivery.
- **Ensures** a transparent, quick, and efficient redistribution workflow.

## ✨ Key Features

### 🍎 For Donors
- **Discovery**: View active food requests from NGOs on an interactive map.
- **Instant Donation**: Select a request and offer surplus food with a few taps.
- **Impact Tracking**: Gamification features like reward points and milestones to encourage regular contributions.

### 🏢 For Organizations (NGOs)
- **Request Creation**: Broadcast specific food needs (e.g., "Feeding 50 people") to the community.
- **Verification**: Verified profiles to ensure trust and safety.
- **History**: Track received donations and impact.

### 🛵 For Riders
- **Automated Assignment**: Receive delivery tasks based on proximity.
- **Delivery Workflow**: Simple "Pick Up" and "Drop Off" status updates.
- **Navigation**: Integrated maps for efficient routing.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.10.4)
- **Backend & Database**: [Supabase](https://supabase.com/) (PostgreSQL, Auth, Realtime)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Maps & Location**: `flutter_map`, `latlong2`, `geolocator`
- **Routing**: `go_router`
- **Notifications**: `flutter_local_notifications`

## 📂 Project Structure

The project follows a feature-first architecture:

```
lib/
├── core/            # Core utilities, theme, and shared widgets
├── features/        # Feature-specific code (Auth, Donor, Organization, Rider)
├── router/          # App navigation configuration
└── main.dart        # Application entry point
```

## ⚙️ Setup Instructions

### Prerequisites
- Flutter SDK installed and configured.
- A Supabase project set up.

### Installation

1.  **Clone the Repository**
    ```bash
    git clone <repository-url>
    cd TeamPulse-CodeSprint26/hunger_n_waste
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Configuration**
    Create a `.env` file in the `hunger_n_waste` root directory and add your Supabase credentials:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```

4.  **Database Setup**
    The application requires specific database tables, types, and RLS policies.
    👉 **[View the detailed Supabase Setup Guide](supabase_setup.md)** to configure your database.

5.  **Run the Application**
    ```bash
    flutter run
    ```

## 🤝 Contribution

This project was built by **Team Pulse** for CodeSprint '26.
