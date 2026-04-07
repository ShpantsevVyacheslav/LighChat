import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { FileQuestion } from 'lucide-react'

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-background text-foreground p-4 text-center">
      <div className="p-6 bg-muted rounded-full mb-6">
        <FileQuestion className="h-12 w-12 text-primary" />
      </div>
      <h2 className="text-3xl font-bold mb-2 font-headline">Страница не найдена</h2>
      <p className="text-muted-foreground max-w-md mb-8">
        К сожалению, запрашиваемая вами страница не существует или была перемещена.
      </p>
      <Button asChild className="rounded-full px-8 h-12 text-base font-bold shadow-lg shadow-primary/20">
        <Link href="/dashboard">
          Вернуться в систему
        </Link>
      </Button>
    </div>
  )
}
