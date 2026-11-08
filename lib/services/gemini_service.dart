import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event_draft.dart';

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<CalendarEventDraft> parseAppointmentFromVoice({
    required String voiceTranscript,
    String? phoneNumber,
    String? knownContactName,
  }) async {
    final now = DateTime.now();
    final italianDateFormat = DateFormat('EEEE d MMMM yyyy, HH:mm', 'it_IT');
    final formattedCurrentTime = italianDateFormat.format(now);

    if (apiKey.isEmpty) {
      // Fallback parser if API key is not yet configured
      return _fallbackParse(
        transcript: voiceTranscript,
        phoneNumber: phoneNumber,
        contactName: knownContactName,
        now: now,
      );
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
Sei un assistente per professionisti (idraulici, elettricisti, artigiani, tecnici).
Il tuo compito è estrarre i dettagli di un appuntamento o sopralluogo a partire dalla nota vocale dell'utente.

CONTESTO ATTUALE:
- Data e ora attuale di riferimento: $formattedCurrentTime
- Numero di telefono del cliente con cui ha appena parlato: ${phoneNumber ?? 'Sconosciuto'}
- Nome registrato in rubrica (se presente): ${knownContactName ?? 'Non in rubrica'}

NOTA VOCALE DETTATA DALL'UTENTE:
"$voiceTranscript"

REGOLE IMPORTANTI:
1. Calcola con precisione la data e ora ("domani", "giovedì prossimo", "alle 15", ecc.) riferendoti alla data attuale.
2. La durata predefinita dell'evento deve essere di 60 minuti, a meno che non sia specificato diversamente.
3. Se nella nota c'è un indirizzo o luogo, inseriscilo in "location".
4. Il titolo deve essere sintetico e chiaro (es. "Sopralluogo caldaia - Mario Rossi").
5. Se il contatto non era in rubrica ma nella nota viene detto il nome della persona, valorizza "contactName" e metti "isNewContact": true.
6. Restituisci SOLO un oggetto JSON valido con questi campi esatti:
{
  "title": "string",
  "startDate": "YYYY-MM-DDTHH:mm:ss",
  "endDate": "YYYY-MM-DDTHH:mm:ss",
  "location": "string o null",
  "description": "string (dettagli intervento ed eventuali note)",
  "contactName": "string o null",
  "isNewContact": boolean
}
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text != null && text.isNotEmpty) {
        final Map<String, dynamic> parsedJson = jsonDecode(text);
        parsedJson['rawTranscript'] = voiceTranscript;
        return CalendarEventDraft.fromJson(
          parsedJson,
          phoneNumber: phoneNumber,
          contactName: knownContactName ?? parsedJson['contactName'],
        );
      }
    } catch (e) {
      print('Errore chiamata Gemini: $e');
    }

    // Fallback if network/API error
    return _fallbackParse(
      transcript: voiceTranscript,
      phoneNumber: phoneNumber,
      contactName: knownContactName,
      now: now,
    );
  }

  CalendarEventDraft _fallbackParse({
    required String transcript,
    String? phoneNumber,
    String? contactName,
    required DateTime now,
  }) {
    // Basic smart fallback: schedule for tomorrow at 10:00 AM
    final tomorrow = now.add(const Duration(days: 1));
    final startTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
    final endTime = startTime.add(const Duration(hours: 1));

    return CalendarEventDraft(
      title: 'Sopralluogo: ${contactName ?? phoneNumber ?? 'Nuovo Cliente'}',
      startTime: startTime,
      endTime: endTime,
      location: null,
      description: 'Dettagli dalla nota: "$transcript"',
      phoneNumber: phoneNumber,
      contactName: contactName,
      isNewContact: contactName == null && phoneNumber != null,
      rawTranscript: transcript,
    );
  }
}
