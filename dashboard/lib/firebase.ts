import { getApp, getApps, initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// Firebase client configuration is public (same Web app registered in Flutter).
// Access is enforced by Firebase Authentication and Firestore Security Rules.
const firebaseConfig = {
  apiKey: "AIzaSyCmZeJbLcwAgbOZfl2ICLQejKiu1_f-Xk0",
  authDomain: "safecar-fca02.firebaseapp.com",
  projectId: "safecar-fca02",
  storageBucket: "safecar-fca02.firebasestorage.app",
  messagingSenderId: "243342109546",
  appId: "1:243342109546:web:39dbd109f0fcaecdf15313",
};

const app = getApps().length ? getApp() : initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
