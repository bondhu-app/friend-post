# ============================================================
      # VERIFY FIREBASE OPTIONS
      # ============================================================

      - name: Verify firebase_options.dart
        shell: bash
        run: |
          set -e

          echo "========================================"
          echo "VERIFYING FIREBASE OPTIONS"
          echo "========================================"

          FILE="lib/firebase_options.dart"

          if [ ! -f "$FILE" ]; then
            echo "ERROR: $FILE not found."
            exit 1
          fi

          echo "Found: $FILE"

          grep -q "class DefaultFirebaseOptions" "$FILE" || {
            echo "ERROR: DefaultFirebaseOptions class not found."
            exit 1
          }

          grep -q "FirebaseOptions" "$FILE" || {
            echo "ERROR: FirebaseOptions not found."
            exit 1
          }

          grep -q "projectId:" "$FILE" || {
            echo "ERROR: projectId not found."
            exit 1
          }

          grep -q "apiKey:" "$FILE" || {
            echo "ERROR: apiKey not found."
            exit 1
          }

          grep -q "appId:" "$FILE" || {
            echo "ERROR: appId not found."
            exit 1
          }

          grep -q "messagingSenderId:" "$FILE" || {
            echo "ERROR: messagingSenderId not found."
            exit 1
          }

          grep -q "storageBucket:" "$FILE" || {
            echo "ERROR: storageBucket not found."
            exit 1
          }

          grep -q "friend-post-fbfdd" "$FILE" || {
            echo "ERROR: Friend Post Firebase project ID not found."
            exit 1
          }

          grep -q "1074705827775" "$FILE" || {
            echo "ERROR: Firebase messaging sender ID not found."
            exit 1
          }

          grep -q "68710467504787bc3a430a" "$FILE" || {
            echo "ERROR: Firebase Android App ID not found."
            exit 1
          }

          grep -q "AIzaSyAbYCTMxhCJzft1dgnpHDRkbC4v9RMU4GE" "$FILE" || {
            echo "ERROR: Firebase API key not found."
            exit 1
          }

          grep -q "TargetPlatform.fuchsia" "$FILE" || {
            echo "ERROR: TargetPlatform.fuchsia case not found."
            exit 1
          }

          echo ""
          echo "Firebase options verified successfully."
          echo "Project: friend-post-fbfdd"
          echo "Android App ID: 1:1074705827775:android:68710467504787bc3a430a"
          echo "Firebase configuration is valid."
