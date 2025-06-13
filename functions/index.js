/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");

const admin = require("firebase-admin");

const fs = require("fs"); // Import the 'fs' module

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

admin.initializeApp();

exports.importExercises = functions.https.onRequest(async (req, res) => {
  try {
    const jsonData = JSON.parse(fs.readFileSync("/tmp/exercises.json",
        "utf-8"));

    const collectionName = "exercises";

    let batch = admin.firestore().batch();

    let count = 0;


    for (const exercise of jsonData) {
      const docRef = admin.firestore().
          collection(collectionName).doc(exercise.id);

      batch.set(docRef, exercise);

      count++;

      if (count % 500 === 0) {
        await batch.commit();

        console.log(`Batch committed. ${count} documents written.`);

        batch = admin.firestore().batch();
      }
    }


    if (count % 500 !== 0) {
      await batch.commit();

      console.log(`Final batch committed. Total ${count} documents written.`);
    }

    console.log("Exercise data import complete!");

    res.status(200).send("Exercise data import complete!");
  } catch (error) {
    console.error("Error importing data:", error);

    res.status(500).send(`Error importing data: ${error}`);
  }
});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });