/// A ready-made expression offered under "Exemplos", like crontab.guru's
/// examples page.
class CronExample {
  const CronExample(this.label, this.expression);

  /// What it does, in plain words.
  final String label;

  final String expression;
}

const cronExamples = <CronExample>[
  CronExample('A cada minuto', '* * * * *'),
  CronExample('A cada 5 minutos', '*/5 * * * *'),
  CronExample('A cada 15 minutos', '*/15 * * * *'),
  CronExample('A cada meia hora', '*/30 * * * *'),
  CronExample('A cada hora', '0 * * * *'),
  CronExample('A cada 2 horas', '0 */2 * * *'),
  CronExample('A cada 6 horas', '0 */6 * * *'),
  CronExample('Todo dia à meia-noite', '0 0 * * *'),
  CronExample('Todo dia às 8h', '0 8 * * *'),
  CronExample('Dias úteis às 9h', '0 9 * * 1-5'),
  CronExample('Fins de semana às 10h', '0 10 * * 0,6'),
  CronExample('Horário comercial, a cada 30 minutos', '*/30 9-17 * * 1-5'),
  CronExample('Toda semana, domingo à meia-noite', '0 0 * * 0'),
  CronExample('Todo mês, no dia 1', '0 0 1 * *'),
  CronExample('A cada trimestre', '0 0 1 */3 *'),
  CronExample('A cada 6 meses', '0 0 1 */6 *'),
  CronExample('Todo ano, em 1º de janeiro', '0 0 1 1 *'),
  CronExample('Ao reiniciar o sistema', '@reboot'),
];
