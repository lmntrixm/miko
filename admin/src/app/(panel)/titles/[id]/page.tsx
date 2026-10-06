'use client';

import { useParams } from 'next/navigation';
import { TitleEditor } from '@/components/TitleEditor';

export default function TitlePage() {
  const { id } = useParams<{ id: string }>();
  return <TitleEditor key={id} titleId={decodeURIComponent(id)} />;
}
