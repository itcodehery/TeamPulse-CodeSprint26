
**Problem Statement ID:** CS01SW

**Team Name:** Team Pulse

**College Name:** CHRIST (Deemed to be University), Central Campus

## Problem Statement
Food waste and hunger are two simultaneous global crises. While massive amounts of food are discarded daily, many communities struggle with food insecurity. The lack of a streamlined logistics network makes it difficult to transfer surplus food to those in need quickly and safely.

## Proposed Solution
HappyMeal is a digital platform designed to bridge the gap between surplus food sources and NGOs. By leveraging real-time location services, the application connects donors with verified organizations to facilitate the efficient redistribution of food.
Our mobile application:
- **Connects** donors (Caterers, Event Organizers, Individuals) with nearby verified NGOs.
- **Facilitates** real-time pickup requests for surplus food.
- **Assigns** riders for collection and delivery.
- **Ensures** a transparent, quick, and efficient redistribution workflow.

## Innovation & Creativity
- **Real-Time Surplus Logistics**: Unlike static directories, our app facilitates dynamic, real-time pickup and delivery of perishable goods using geolocation.
- **Role-Based Ecosystem**: Integrates three distinct user roles (Donor, NGO, Rider) into a single cohesive ecosystem.
- **Automated Rider Assignment**: Smart assignment logic ensures the nearest available rider is tasked with the pickup, minimizing food spoilage risk.

## Technical Complexity & Stack
This project leverages a modern, cross-platform tech stack to ensure performance and scalability:

- **Mobile Framework**: Flutter (SDK ^3.10.4) - For a high-performance, cross-platform (iOS/Android) user interface.
- **Backend & Database**: Supabase - Utilized for PostgreSQL database, Authentication, and Realtime subscriptions.
- **State Management**: flutter_riverpod - For robust and scalable application state management.
- **Maps & Location Services**: 
  - `flutter_map` & `latlong2`: For rendering interactive maps.
  - `geolocator`: For real-time user location tracking.
- **Routing**: go_router - For declarative and deep-linkable navigation.
- **Notifications**: flutter_local_notifications - For local user alerts.
- **Architecture**: Feature-first architecture ensuring modularity and maintainability.

## Usability & Impact
**Users:**
1.  **Donors**: Individuals, restaurants, or event organizers who have surplus food.
2.  **NGOs**: Verified non-profit organizations seeking food for their beneficiaries.
3.  **Riders**: Volunteers or logistics partners who transport the food.

**Interaction:**
- Donors view active requests on a map and offer food with a few taps.
- NGOs broadcast specific needs (e.g., "Lunch for 50") and verify incoming donations.
- Riders receive automated delivery tasks based on proximity to the donor.

**Impact:**
- **Social**: Directly alleviates hunger in local communities by routing excess food to where it's needed most.
- **Environmental**: Reduces food waste, thereby lowering the carbon footprint associated with decomposing organic waste in landfills.

## Setup Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured.
- A [Supabase](https://supabase.com/) project set up.

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

## Presentation/Demo Link (Optional)
https://www.canva.com/design/DAG_6F8yvZE/jRHUYZon5fQ9f1FXYvJ6Ow/view?utm_content=DAG_6F8yvZE&utm_campaign=designshare&utm_medium=link2&utm_source=uniquelinks&utlId=ha19d8485f9