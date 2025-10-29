# Trail: Leave a Trail of Efforts

## Description

Trail is a decentralized productivity application designed to help you put all your goals and daily efforts on-chain forever. Leave a permanent, immutable trail of your efforts, track your progress, and build a public record of your achievements powered by AI and blockchain technology.

Set time-bound goals, and when you mark them as complete, an AI-powered judge will quiz you to verify your accomplishment. A permanent attestation of your success (or failure) is then recorded on the blockchain using the Ethereum Attestation Service (EAS). Our platform also features a vibrant social community where you can discover and follow other users' trails, track their progress, and draw inspiration from their journeys.

Built on the scaffold-eth-2 boilerplate, Trail offers a modern, intuitive, and visually appealing user experience with a calming lavender theme.

## Features

*   **User Authentication:** Secure user login and profile management.
*   **Goal Setting:** Create goals with titles, descriptions, and deadlines.
*   **AI-Powered Judge:** An LLM-based quiz system to verify goal completion.
*   **Blockchain Attestations:** Immutable proof of your achievements on the blockchain via EAS, creating a permanent "trail of effort."
*   **Social Discovery:** A "Discovery" page to look up and view public user profiles.
*   **Social Feed:** A running feed of all public goals and their statuses.
*   **Public/Private Profiles:**
    *   **Public Profiles:** Display user stats like completion percentage, max streak, and current streak. Showcase completed, failed, and pending goals with links to blockchain proofs.
    *   **Private Profiles:** All the features of public profiles, plus the ability to add new goals, mark goals as complete, and add private notes.
*   **Modern UI/UX:** A clean, user-friendly interface.
*   **Seamless Navigation:** Easily switch between your private profile, the discovery page, the social feed, and sign-out options from a persistent top navigation bar.

## Tech Stack

*   **Frontend:** Next.js, RainbowKit, Wagmi, Tailwind CSS
*   **Backend:** Node.js, Express.js (or similar)
*   **Database:** PostgreSQL (or your preferred SQL/NoSQL database)
*   **Blockchain:** Solidity, Hardhat, Ethereum Attestation Service (EAS)
*   **AI:** OpenAI API

## Getting Started

### Prerequisites

*   Node.js (v18 or later)
*   Yarn
*   Git

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/scaffold-eth/scaffold-eth-2.git
    cd scaffold-eth-2
    ```
2.  **Install dependencies:**
    ```bash
    yarn install
    ```
3.  **Run the development server:**
    ```bash
    yarn start
    ```

## Usage

1.  **Connect Your Wallet:** Connect your Ethereum wallet (e.g., MetaMask) to the application.
2.  **Create Your Profile:** Set up your user profile with a username and any other required information.
3.  **Set a Goal:** Navigate to your private profile and click "New Goal" to create a new goal with a title, description, and deadline.
4.  **Complete a Goal:** When you've completed a goal, click "Mark as Complete" on your private profile.
5.  **Take the Quiz:** Answer the two AI-generated questions to verify your accomplishment.
6.  **View Your Attestation:** Once you've completed the quiz, an attestation will be uploaded to the blockchain. You can view it via the link on your profile, which forms part of your permanent trail.
7.  **Explore:** Browse the "Discovery" and "Social" pages to see what other users are working on.
