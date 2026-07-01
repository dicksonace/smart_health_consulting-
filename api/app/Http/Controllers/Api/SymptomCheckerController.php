<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SymptomCheckerLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SymptomCheckerController extends Controller
{
    private const DISCLAIMER = 'This is guidance only — not a medical diagnosis. Always consult a qualified healthcare provider for proper evaluation.';

    /** @var array<string, array{specialty: string, urgency: string}> */
    private const SYMPTOM_RULES = [
        'chest pain' => ['specialty' => 'Cardiology', 'urgency' => 'emergency'],
        'shortness of breath' => ['specialty' => 'Pulmonology', 'urgency' => 'emergency'],
        'severe headache' => ['specialty' => 'Neurology', 'urgency' => 'high'],
        'high fever' => ['specialty' => 'General Practice', 'urgency' => 'high'],
        'rash' => ['specialty' => 'Dermatology', 'urgency' => 'medium'],
        'skin rash' => ['specialty' => 'Dermatology', 'urgency' => 'medium'],
        'cough' => ['specialty' => 'General Practice', 'urgency' => 'low'],
        'sore throat' => ['specialty' => 'General Practice', 'urgency' => 'low'],
        'back pain' => ['specialty' => 'Orthopedics', 'urgency' => 'medium'],
        'joint pain' => ['specialty' => 'Orthopedics', 'urgency' => 'medium'],
        'anxiety' => ['specialty' => 'Psychiatry', 'urgency' => 'medium'],
        'depression' => ['specialty' => 'Psychiatry', 'urgency' => 'medium'],
        'abdominal pain' => ['specialty' => 'Gastroenterology', 'urgency' => 'high'],
        'nausea' => ['specialty' => 'General Practice', 'urgency' => 'low'],
        'fatigue' => ['specialty' => 'General Practice', 'urgency' => 'low'],
        'dizziness' => ['specialty' => 'General Practice', 'urgency' => 'medium'],
        'palpitations' => ['specialty' => 'Cardiology', 'urgency' => 'high'],
    ];

    private const URGENCY_RANK = [
        'low' => 1,
        'medium' => 2,
        'high' => 3,
        'emergency' => 4,
    ];

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'symptoms' => ['required', 'array', 'min:1'],
            'symptoms.*' => ['required', 'string'],
        ]);

        $result = $this->analyzeSymptoms($validated['symptoms']);
        $result['disclaimer'] = self::DISCLAIMER;
        $result['suggested_actions'] = $this->suggestedActions($result['urgency'], $result['specialty']);

        $logData = [
            'symptoms' => $validated['symptoms'],
            'suggested_specialty' => $result['specialty'],
            'urgency' => $result['urgency'],
        ];

        if ($request->user()?->patient) {
            $log = SymptomCheckerLog::create([
                'patient_id' => $request->user()->patient->id,
                ...$logData,
            ]);
            $result['log_id'] = $log->id;
        }

        return response()->json($result);
    }

    /**
     * @param  array<int, string>  $symptoms
     * @return array{specialty: string, urgency: string, matched_symptoms: array<int, string>}
     */
    private function analyzeSymptoms(array $symptoms): array
    {
        $normalized = array_map(fn ($s) => strtolower(trim($s)), $symptoms);
        $matched = [];
        $specialty = 'General Practice';
        $urgency = 'low';

        foreach ($normalized as $symptom) {
            foreach (self::SYMPTOM_RULES as $pattern => $rule) {
                if (str_contains($symptom, $pattern) || str_contains($pattern, $symptom)) {
                    $matched[] = $symptom;

                    if (self::URGENCY_RANK[$rule['urgency']] >= self::URGENCY_RANK[$urgency]) {
                        $urgency = $rule['urgency'];
                        $specialty = $rule['specialty'];
                    }
                }
            }
        }

        return [
            'specialty' => $specialty,
            'urgency' => $urgency,
            'matched_symptoms' => array_values(array_unique($matched)),
        ];
    }

    /** @return array<int, string> */
    private function suggestedActions(string $urgency, string $specialty): array
    {
        return match ($urgency) {
            'emergency' => [
                'Call emergency services or go to the nearest emergency department immediately.',
                'Do not rely on this app for urgent life-threatening symptoms.',
            ],
            'high' => [
                'Book an urgent appointment with a '.$specialty.' specialist.',
                'Seek in-person care within 24 hours if symptoms worsen.',
            ],
            'medium' => [
                'Book a consultation with a '.$specialty.' doctor within the next few days.',
                'Monitor symptoms and note any changes.',
            ],
            default => [
                'Consider booking a routine appointment with a '.$specialty.' doctor.',
                'Rest, stay hydrated, and monitor your symptoms.',
            ],
        };
    }
}
