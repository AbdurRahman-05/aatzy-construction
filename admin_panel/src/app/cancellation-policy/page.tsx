import { redirect } from 'next/navigation';

export default function CancellationRedirect() {
  redirect('/refund-policy');
}
