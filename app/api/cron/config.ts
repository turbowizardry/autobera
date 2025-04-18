import cron from 'node-cron';

export const CRON_SCHEDULES = {
  // Run every 5 hours
  CLAIM_CHECK: '0 */5 * * *',
  
  // Run daily at midnight
  VAULT_SYNC: '0 0 * * *',
  
  // Run every hour
  PERMISSION_SYNC: '0 * * * *'
} as const;

export function validateCronSchedule(schedule: string): boolean {
  return cron.validate(schedule);
}

export function formatNextRun(schedule: string): string {
  if (!validateCronSchedule(schedule)) {
    throw new Error('Invalid cron schedule');
  }
  
  const task = cron.schedule(schedule, () => {});
  const next = task.nextDate();
  task.stop();
  
  return next.toISOString();
} 