<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Appointment Reminder</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.5; color: #333;">
    <h2>Smart Health — Appointment Reminder</h2>
    <p>Hello {{ $appointment->patient->user->name }},</p>
    <p>This is a reminder that your appointment is in <strong>{{ $windowLabel }}</strong>.</p>
    <ul>
        <li><strong>Doctor:</strong> {{ $appointment->doctor->user->name }}</li>
        <li><strong>When:</strong> {{ $appointment->scheduled_at->format('l, M j Y \a\t g:i A') }}</li>
        <li><strong>Type:</strong> {{ ucfirst(str_replace('_', ' ', $appointment->type)) }}</li>
    </ul>
    @if($appointment->type === 'video')
        <p>Open the Smart Health app and tap <strong>Join Video Call</strong> five minutes before your scheduled time.</p>
    @endif
    <p style="color:#666;font-size:12px;">Smart Health Consulting — automated reminder</p>
</body>
</html>
