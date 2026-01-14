import { NextResponse } from 'next/server';

export async function POST(req: Request) {
    try {
        const { messages, context } = await req.json();

        if (!process.env.GROQ_API_KEY) {
            return NextResponse.json({ error: 'GROQ_API_KEY not configured' }, { status: 500 });
        }

        // System prompt with Context Injection
        let systemContent = 'You are Sobat AI, a helpful, witty, and friendly HR assistant for the "Sobat HR" application. Your goal is to assist users (HR staff) with their tasks, answer questions about HR processes, or just provides jokes and stress relief. Keep answers concise and helpful. Use emoji occasionally. Speak in Indonesian (Bahasa Indonesia) mixed with English (Java-English slang if appropriate but keep it professional enough).';

        if (context) {
            systemContent += `\n\n[SYSTEM DATA CONTEXT]\nYou have access to real-time system data. Use this to answer questions:\n`;
            systemContent += `- **Capabilities**: What the system can do (see 'capabilities').\n`;
            systemContent += `- **Stats**: Current operational status (see 'system_stats').\n`;
            systemContent += `- **Employees**: Recent employee list (see 'employees_sample').\n`;
            systemContent += `- **Payroll**: Recent payroll summaries (see 'recent_payrolls').\n\n`;
            systemContent += `DATA:\n${JSON.stringify(context, null, 2)}\n[END CONTEXT]`;
        }

        const systemMessage = {
            role: 'system',
            content: systemContent
        };

        const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'llama-3.3-70b-versatile', // Updated to supported model
                messages: [systemMessage, ...messages],
                temperature: 0.7,
                max_tokens: 1024,
            }),
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Groq API Error:', errorText);
            return NextResponse.json({ error: 'Failed to communicate with AI' }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);

    } catch (error) {
        console.error('Chat API Error:', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
