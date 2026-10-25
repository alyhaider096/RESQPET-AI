# AnimalCare PK Product Steering

## Product Vision

AnimalCare PK is an AI-assisted animal welfare operating system connecting citizens, pet owners, livestock farmers, NGOs, rescue teams, veterinarians, and responsible adopters across Pakistan.

## Target Users

- Public reporters (emergency situations)
- Pet owners (urban areas)
- Livestock farmers (rural areas)
- NGO coordinators (rescue operations management)
- Rescue volunteers (field responders)
- Veterinarians (consultations and treatment)
- Adopters (recovered animal adoption)
- System administrators (platform oversight)

## Core Capabilities

### Emergency Rescue (P0 - MUST SHIP)
- Multi-channel rescue reporting (voice, mobile app)
- Explainable priority classification
- Real-time case assignment and tracking
- Status updates with audit trail

### Animal Profile Management (P0)
- Individual animals and herd/flock records
- Photo, video, and voice note support
- Health and vaccination history
- Rescue and consultation history

### Veterinary Services (P1 - After P0 stable)
- Consultation request workflow
- Appointment scheduling
- Consultation notes and follow-up

### Adoption System (P1)
- Recovered animal listing
- Application and approval workflow
- Adoption follow-up

### Reproductive Health (P1)
- Basic reproductive-health records
- Veterinary referral for complications

## Animals in Scope

The system must support both urban pets and rural livestock:
- **Livestock**: Cattle, buffaloes, goats, sheep, poultry, horses, donkeys
- **Pets**: Dogs, cats
- **Working animals**: Donkeys, horses

This is not only a "cute cats-and-dogs" application—it must be practical for Pakistan's diverse animal welfare needs.

## Rural UX Considerations

- Bilingual interface (English and Urdu-ready)
- Icon-led navigation with simple wording
- Large touch targets for field use
- Low-data optimized (image compression, short videos)
- Voice note support
- Manual village/district entry
- Phone/SMS fallback reference
- Offline draft saving (not full synchronization during hackathon)

## AI Boundaries

### AI May:
- Classify intent from voice or text
- Extract structured fields from conversations
- Summarize rescue reports and consultations
- Apply transparent priority rules
- Recommend responders or veterinarians using declared factors

### AI Must Not:
- Diagnose animal conditions
- Autonomously prescribe medicine
- Guarantee rescue response times
- Make adoption or dispatch decisions without human review

## Priority Levels

### P0 - MUST SHIP (Hackathon Demo)
Complete vertical slice of emergency rescue workflow from voice call to resolution.

### P1 - ONLY AFTER P0 IS STABLE
Veterinary consultations, adoption system, reproductive-health records.

### P2 - AFTER THE HACKATHON
Production medical imaging, breeding-partner matching, native video calls, payments, offline sync, social features.

## Success Criteria

- Complete rescue workflow demonstrable in <5 minutes
- Working release APK
- Clear Kiro specification artifacts
- Meaningful test coverage
- Secure architecture (no exposed secrets)
- Open-source ready (proper license, documentation)
- Reuse transparency documented
