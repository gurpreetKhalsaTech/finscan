# FinScan

A Flutter app that scans credit/debit cards and bank passbooks using on-device OCR, extracts structured data, and displays it clearly — with no backend or third-party parsing libraries.

---

## Steps to Run the Project

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | ≥ 3.10.0 |
| Dart SDK | ≥ 3.10.0 |
| Xcode (iOS) | ≥ 15 |
| Android Studio / SDK | API 21+ |

### 1. Clone and install dependencies

```bash
git clone <repo-url>
cd finscan
flutter pub get
```

### 2. iOS — add permission descriptions

In `ios/Runner/Info.plist`, ensure these keys are present (they are already added):

```xml
<key>NSCameraUsageDescription</key>
<string>Used to scan cards and passbooks</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to pick passbook images from your gallery</string>
```

### 3. Android — permissions

`android/app/src/main/AndroidManifest.xml` already includes:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### 4. Run

```bash
# On a connected device or simulator
flutter run

# Run all tests
flutter test
```

---

## Libraries Used

| Library | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.6.1 | State management (ViewModel / providers) |
| `go_router` | ^14.6.3 | Declarative navigation |
| `camera` | ^0.11.0+2 | Live camera preview and image capture |
| `google_mlkit_text_recognition` | ^0.13.1 | On-device OCR (Latin script) |
| `permission_handler` | ^11.3.1 | Runtime camera permission requests |
| `image_picker` | ^1.1.2 | Gallery image upload for passbook scanner |

**No library is used for parsing.** All extraction logic (card number, expiry, IFSC, account number, holder name, bank name, branch name, MICR) is implemented manually using Dart regex and string operations. CIF / Customer ID / UCIC and PAN are detected and excluded from account number candidates but are not surfaced as output fields.

---

## Assumptions Made

1. **Card numbers are 13–19 digits** — covers Visa (13/16), Mastercard (16), RuPay (16), Amex (15), Discover (16), and Diners (14). The card number regex matches digit groups across that range.
2. **Card holder name appears above the card number** in ALL-CAPS on the physical card. If OCR returns it elsewhere, labeled fallbacks (`NAME:`, `A/C NAME:`) are used for passbooks.
3. **Expiry year is two digits** in the range 20–39, covering years 2020–2039. Years outside this range are not matched to avoid false positives.
4. **IFSC codes are 11 characters** — 4 uppercase letters, literal `0`, then 6 alphanumeric characters. IFSC is extracted from the *original* OCR text before any numeric correction, because corrections like `S→5` or `B→8` would corrupt the alphabetic bank prefix (e.g. `SBIN` → `581N`).
5. **Account numbers are 9–18 digits** (covers SBI=11, HDFC=14, ICICI=12, Axis=15, Kotak=14, PNB=16, etc.). When multiple candidates exist, a labeled match (`A/C NO`, `ACCOUNT NO`, `SB A/C NO`) is preferred; otherwise the longest candidate is selected.
6. **Account number labels may contain spaced digit groups** (e.g. `1141 2952 622`). The labeled-account regex strips spaces after extraction.
7. **CIF / Customer ID / UCIC are bank-specific names for the same concept.** SBI CIF is 11 digits — the same length as an SBI account number — so it must be labeled and excluded from account number candidates. HDFC uses "Customer ID"; Union Bank uses "UCIC". All variants are matched and excluded.
8. **OCR language is Latin/English.** ML Kit is initialised with `TextRecognitionScript.latin`. Passbooks in regional-script-only text will not parse correctly.
9. **Single card / single passbook page per scan.** The app captures one image at a time and parses it as a single document.

---

## What Was Skipped and Why

| Item | Reason |
|------|--------|
| **CVV extraction** | CVV must never be stored or displayed per PCI-DSS guidelines. The regex exists in `RegexPatterns` for detection only; it is intentionally not surfaced in the UI or model. |
| **Backend / cloud OCR** | Explicitly prohibited by the requirements. All processing is on-device. |
| **Card scanner gallery upload** | The card scanner is camera-only. The passbook scanner supports both camera and gallery (`image_picker`). Cards are typically scanned live, so gallery upload was omitted for the card flow. |
| **Multi-page passbook scanning** | Out of scope. The feature targets the front/data page of a passbook. Scanning transaction pages is a different problem domain. |
| **Tablet / landscape layouts** | No layout requirement was specified. The UI is portrait-first and functional on tablets but not optimised. |
| **Passbook account number masking** | Account numbers on passbooks are typically shared openly (e.g. for NEFT/UPI). Unlike card numbers, masking them would reduce usability with no security benefit in this context. |
| **Offline Tesseract OCR** | ML Kit Text Recognition was chosen over Tesseract because it ships as a smaller on-device model with better accuracy on printed text and no native compilation overhead. |

---

## Architecture Overview

```
lib/
├── core/               # Shared constants, regex patterns, theme, utils
├── features/
│   ├── card_scanner/   # Camera → OCR → CardParser → Luhn → CardResultScreen
│   └── passbook_scanner/ # Camera/Gallery → OCR → PassbookParser → PassbookResultScreen
└── shared/             # OcrService, CameraService, reusable widgets
```

**`CardDetails`** fields: `cardNumber`, `maskedCardNumber`, `expiryDate`, `cardHolderName`, `cardNetwork`, `bankName`, `isValid`.

**`BankDetails`** fields: `accountHolderName`, `accountNumber`, `ifscCode`, `micrCode`, `bankName`, `branchName`.

State is managed with Riverpod Notifiers. Navigation uses GoRouter with typed `extra` payloads. Parsing is fully pure-Dart and covered by unit tests.

---

## Evaluation Notes

| Area | Implementation |
|------|----------------|
| **Parsing Logic (40%)** | Manual regex + heuristics for all fields; Luhn validation; OCR error correction; labeled-match-first strategy for ambiguous fields; CIF/Customer ID/UCIC exclusion; spaced account number group support |
| **Code Quality (25%)** | Feature-first folder structure; single-responsibility classes; no business logic in widgets |
| **OCR + Camera (20%)** | ML Kit on-device OCR; live camera with overlay guide; gallery fallback for passbook |
| **Tests (15%)** | 60 tests across `LuhnValidator` (12), `CardParser` (25), `PassbookParser` (22), `WidgetTest` (1) — 56 passing, 4 failing |