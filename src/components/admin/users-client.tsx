"use client";

import { useState, useMemo, useCallback } from "react";
import { useRouter } from "next/navigation";
import type { User, UserRole } from "@/lib/types";
import { useAuth } from "@/hooks/use-auth";
import { ROLES } from "@/lib/constants";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  MoreHorizontal,
  PlusCircle,
  Trash2,
  Edit,
  Loader2,
  ArrowUpDown,
  Calendar,
  UserCog,
  Ban,
  ShieldCheck,
  ShieldOff,
  KeyRound,
} from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { formatPhoneNumberForDisplay } from "@/lib/phone-utils";
import { Card, CardHeader, CardTitle, CardContent } from "../ui/card";
import { useAuth as useFirebaseAuth, useFirestore, useCollection, useMemoFirebase } from "@/firebase";
import { collection, deleteField, doc, query, updateDoc } from "firebase/firestore";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { format, parseISO } from "date-fns";
import { ru } from "date-fns/locale";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import { UserBlockDialog } from "@/components/admin/user-block-dialog";
import { AdminResetPasswordDialog } from "@/components/admin/admin-reset-password-dialog";
import { isAccountBlocked } from "@/lib/account-block-utils";
import { useToast } from "@/hooks/use-toast";

interface UsersClientProps {
  /** Скрыть верхний заголовок страницы (вкладка админки). */
  embedded?: boolean;
}

export function UsersClient({ embedded = false }: UsersClientProps) {
  const firestore = useFirestore();
  const firebaseAuth = useFirebaseAuth();
  const { user: currentUser } = useAuth();
  const { toast } = useToast();
  const [searchTerm, setSearchTerm] = useState("");
  const [blockTarget, setBlockTarget] = useState<User | null>(null);
  const [resetTarget, setResetTarget] = useState<User | null>(null);
  const [sortConfig, setSortConfig] = useState<{ key: string; direction: 'asc' | 'desc' } | null>({ key: 'createdAt', direction: 'desc' });
  const router = useRouter();

  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(25);

  const usersQuery = useMemoFirebase(() => (firestore ? query(collection(firestore, 'users')) : null), [firestore]);
  const { data: users, isLoading: isUsersLoading } = useCollection<User>(usersQuery);

  const adminCount = useMemo(
    () => (users || []).filter((u) => u.role === "admin" && !u.deletedAt).length,
    [users]
  );
  const isAdmin = currentUser?.role === "admin";

  const getIdToken = useCallback(async () => {
    const u = firebaseAuth.currentUser;
    if (!u) return null;
    return u.getIdToken();
  }, [firebaseAuth]);

  const handleUnblock = async (user: User) => {
    if (!firestore) return;
    try {
      await updateDoc(doc(firestore, "users", user.id), {
        accountBlock: deleteField(),
      });
      toast({ title: "Блокировка снята" });
    } catch (e) {
      console.error(e);
      toast({ variant: "destructive", title: "Не удалось разблокировать" });
    }
  };

  const handleSetRole = async (user: User, role: UserRole) => {
    if (!firestore) return;
    if (user.role === "admin" && role === "worker" && adminCount <= 1) {
      toast({ variant: "destructive", title: "Нельзя снять последнего администратора" });
      return;
    }
    try {
      await updateDoc(doc(firestore, "users", user.id), { role });
      toast({
        title: role === "admin" ? "Назначен администратором" : "Роль изменена на участника",
      });
    } catch (e) {
      console.error(e);
      toast({ variant: "destructive", title: "Не удалось обновить роль" });
    }
  };

  const filteredUsers = useMemo(() => (users || [])
    .filter(user => !user.deletedAt)
    .filter((user) =>
        user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (user.phone && user.phone.includes(searchTerm))
  ), [users, searchTerm]);

  const toTime = (val: any) => {
    if (!val) return 0;
    if (typeof val.toDate === 'function') return val.toDate().getTime();
    if (typeof val === 'string') {
        try {
            return parseISO(val).getTime();
        } catch (e) {
            return new Date(val).getTime();
        }
    }
    return new Date(val).getTime();
  };

  const sortedUsers = useMemo(() => {
    let sortableItems = [...filteredUsers];
    if (sortConfig !== null) {
      sortableItems.sort((a, b) => {
        let aVal: any;
        let bVal: any;

        switch (sortConfig.key) {
          case 'name':
            aVal = a.name.toLowerCase();
            bVal = b.name.toLowerCase();
            break;
          case 'role':
            aVal = (a.role ? ROLES[a.role] : '').toLowerCase();
            bVal = (b.role ? ROLES[b.role] : '').toLowerCase();
            break;
          case 'createdAt':
            aVal = toTime(a.createdAt);
            bVal = toTime(b.createdAt);
            break;
          default:
            aVal = (a as any)[sortConfig.key];
            bVal = (b as any)[sortConfig.key];
        }

        if (aVal < bVal) return sortConfig.direction === 'asc' ? -1 : 1;
        if (aVal > bVal) return sortConfig.direction === 'asc' ? 1 : -1;
        return 0;
      });
    }
    return sortableItems;
  }, [filteredUsers, sortConfig]);

  const paginatedUsers = useMemo(() => {
    const startIndex = (currentPage - 1) * pageSize;
    return sortedUsers.slice(startIndex, startIndex + pageSize);
  }, [sortedUsers, currentPage, pageSize]);

  const totalPages = useMemo(() => {
    const total = Math.ceil(filteredUsers.length / pageSize);
    return total > 0 ? total : 1;
  }, [filteredUsers, pageSize]);

  const handleSort = (key: string) => {
    let direction: 'asc' | 'desc' = 'asc';
    if (sortConfig && sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  const PaginationControls = () => (
    <div className="flex flex-col sm:flex-row items-center justify-between mt-4 gap-4">
        <div className="flex items-center gap-2">
            <span className="text-sm text-muted-foreground">На странице:</span>
            <Select value={String(pageSize)} onValueChange={(value) => { setPageSize(Number(value)); setCurrentPage(1); }}>
                <SelectTrigger className="w-[80px] rounded-full h-9">
                    <SelectValue placeholder={String(pageSize)} />
                </SelectTrigger>
                <SelectContent>
                    {[10, 25, 50].map(size => (
                        <SelectItem key={size} value={String(size)}>{size}</SelectItem>
                    ))}
                </SelectContent>
            </Select>
        </div>
        <div className="flex items-center gap-4">
            <span className="text-sm text-muted-foreground">
                Страница {currentPage} из {totalPages}
            </span>
            <div className="flex items-center gap-2">
                <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1 || isUsersLoading} className="rounded-full">
                    Назад
                </Button>
                <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages || isUsersLoading} className="rounded-full">
                    Вперед
                </Button>
            </div>
        </div>
    </div>
  );

  const formatDate = (dateVal: any) => {
      if (!dateVal) return '—';
      try {
          const date = typeof dateVal.toDate === 'function' ? dateVal.toDate() : (typeof dateVal === 'string' ? parseISO(dateVal) : new Date(dateVal));
          return format(date, "dd.MM.yyyy", { locale: ru });
      } catch (e) {
          return '—';
      }
  };

  return (
    <div className="space-y-6">
      {!embedded && (
        <div className="animate-in fade-in slide-in-from-top-4 duration-700 flex items-center gap-2">
          <div className="min-w-0">
            <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 leading-tight">
              <UserCog className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> Пользователи
            </h1>
            <p className="text-xs sm:text-sm text-muted-foreground">Управление учетными записями сотрудников и их ролями.</p>
          </div>
        </div>
      )}

      <div className="flex items-center justify-between gap-4">
        <Input
          placeholder="Поиск по имени, email или телефону..."
          value={searchTerm}
          tabIndex={-1}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full max-w-lg rounded-full"
        />
        <Button onClick={() => router.push('/dashboard/users/new')} size="icon" aria-label="Добавить пользователя" className="rounded-full shadow-lg shadow-primary/20">
            <PlusCircle className="h-4 w-4" />
        </Button>
      </div>
      <div className="rounded-xl border hidden md:block overflow-hidden bg-white/50 dark:bg-black/20">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>
                <Button variant="ghost" onClick={() => handleSort('name')} className="hover:bg-transparent p-0 font-semibold h-auto">
                  Пользователь <ArrowUpDown className="ml-2 h-4 w-4" />
                </Button>
              </TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Телефон</TableHead>
              <TableHead>
                <Button variant="ghost" onClick={() => handleSort('role')} className="hover:bg-transparent p-0 font-semibold h-auto">
                  Роль <ArrowUpDown className="ml-2 h-4 w-4" />
                </Button>
              </TableHead>
              <TableHead>
                <Button variant="ghost" onClick={() => handleSort('createdAt')} className="hover:bg-transparent p-0 font-semibold h-auto">
                  Добавлен <ArrowUpDown className="ml-2 h-4 w-4" />
                </Button>
              </TableHead>
              <TableHead><span className="sr-only">Действия</span></TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isUsersLoading ? (
              <TableRow>
                <TableCell colSpan={6} className="h-24 text-center">
                  <Loader2 className="mx-auto h-6 w-6 animate-spin text-primary" />
                  <p className="mt-2 text-muted-foreground">Загрузка пользователей...</p>
                </TableCell>
              </TableRow>
            ) : paginatedUsers.length > 0 ? (
              paginatedUsers.map((user) => (
                <TableRow key={user.id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                        <Avatar className="border border-white/10 shadow-sm">
                            <AvatarImage src={user.avatar} alt={user.name} className="object-cover" />
                            <AvatarFallback>{user.name.charAt(0)}</AvatarFallback>
                        </Avatar>
                        <span className="font-medium truncate max-w-[150px]">{user.name}</span>
                    </div>
                  </TableCell>
                  <TableCell className="max-w-[200px] truncate" title={user.email}>{user.email}</TableCell>
                  <TableCell>{formatPhoneNumberForDisplay(user.phone)}</TableCell>
                  <TableCell>
                    <div className="flex flex-wrap items-center gap-1.5">
                      <Badge variant="outline" className="rounded-full bg-muted/50">
                        {user.role ? ROLES[user.role] : "—"}
                      </Badge>
                      {isAccountBlocked(user) && (
                        <Badge variant="destructive" className="rounded-full text-xs">
                          Заблокирован
                        </Badge>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                      <span className="text-sm opacity-70">{formatDate(user.createdAt)}</span>
                  </TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                        <Button variant="ghost" className="h-8 w-8 p-0 rounded-full">
                            <span className="sr-only">Открыть меню</span>
                            <MoreHorizontal className="h-4 w-4" />
                        </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end" className="rounded-xl shadow-2xl border-none">
                        <DropdownMenuItem onSelect={() => router.push(`/dashboard/users/${user.id}/edit`)}>
                            <Edit className="mr-2 h-4 w-4" />
                            Редактировать
                        </DropdownMenuItem>
                        {isAdmin && (
                          <>
                            <DropdownMenuSeparator />
                            {isAccountBlocked(user) ? (
                              <DropdownMenuItem onSelect={() => void handleUnblock(user)}>
                                <ShieldOff className="mr-2 h-4 w-4" />
                                Разблокировать
                              </DropdownMenuItem>
                            ) : (
                              <DropdownMenuItem
                                onSelect={() => setBlockTarget(user)}
                                disabled={currentUser?.id === user.id}
                              >
                                <Ban className="mr-2 h-4 w-4" />
                                Заблокировать
                              </DropdownMenuItem>
                            )}
                            <DropdownMenuItem onSelect={() => setResetTarget(user)}>
                              <KeyRound className="mr-2 h-4 w-4" />
                              Сбросить пароль
                            </DropdownMenuItem>
                            {user.role !== "admin" && (
                              <DropdownMenuItem onSelect={() => void handleSetRole(user, "admin")}>
                                <ShieldCheck className="mr-2 h-4 w-4" />
                                Сделать администратором
                              </DropdownMenuItem>
                            )}
                            {user.role === "admin" && (
                              <DropdownMenuItem
                                onSelect={() => void handleSetRole(user, "worker")}
                                disabled={
                                  currentUser?.id === user.id ||
                                  (adminCount <= 1 && user.role === "admin")
                                }
                              >
                                <ShieldOff className="mr-2 h-4 w-4" />
                                Снять роль администратора
                              </DropdownMenuItem>
                            )}
                          </>
                        )}
                        <DropdownMenuSeparator />
                        <DropdownMenuItem
                            className="text-destructive focus:text-destructive"
                            onSelect={() => router.push(`/dashboard/users/${user.id}/delete`)}
                            disabled={currentUser?.id === user.id}
                        >
                            <Trash2 className="mr-2 h-4 w-4" />
                            Удалить
                        </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={6} className="h-24 text-center">
                  Пользователи не найдены.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      
      <div className="md:hidden space-y-3">
        {isUsersLoading ? (
            <div className="text-center text-muted-foreground pt-10">
                <Loader2 className="mx-auto h-6 w-6 animate-spin text-primary" />
                <p className="mt-2">Загрузка пользователей...</p>
            </div>
        ) : paginatedUsers.length > 0 ? (
          paginatedUsers.map((user) => (
            <Card key={user.id} className="w-full rounded-3xl overflow-hidden border-white/10 shadow-lg">
              <CardHeader className="pb-3">
                <div className="flex justify-between items-start gap-2">
                  <div className="flex items-center gap-3 min-w-0">
                    <Avatar className="shrink-0 border border-white/10 shadow-sm">
                      <AvatarImage src={user.avatar} alt={user.name} className="object-cover" />
                      <AvatarFallback>{user.name.charAt(0)}</AvatarFallback>
                    </Avatar>
                    <div className="min-w-0">
                      <CardTitle className="text-base leading-tight truncate">{user.name}</CardTitle>
                      <div className="mt-0.5 flex flex-wrap items-center gap-1">
                        <p className="text-[10px] uppercase font-bold text-primary tracking-wider">
                          {user.role ? ROLES[user.role] : "—"}
                        </p>
                        {isAccountBlocked(user) && (
                          <Badge variant="destructive" className="rounded-full px-1.5 py-0 text-[9px]">
                            Заблокирован
                          </Badge>
                        )}
                      </div>
                    </div>
                  </div>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" className="h-8 w-8 p-0 shrink-0 rounded-full">
                        <span className="sr-only">Открыть меню</span>
                        <MoreHorizontal className="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end" className="rounded-xl shadow-2xl border-none">
                      <DropdownMenuItem onSelect={() => router.push(`/dashboard/users/${user.id}/edit`)}>
                        <Edit className="mr-2 h-4 w-4" />
                        Редактировать
                      </DropdownMenuItem>
                      {isAdmin && (
                        <>
                          <DropdownMenuSeparator />
                          {isAccountBlocked(user) ? (
                            <DropdownMenuItem onSelect={() => void handleUnblock(user)}>
                              <ShieldOff className="mr-2 h-4 w-4" />
                              Разблокировать
                            </DropdownMenuItem>
                          ) : (
                            <DropdownMenuItem
                              onSelect={() => setBlockTarget(user)}
                              disabled={currentUser?.id === user.id}
                            >
                              <Ban className="mr-2 h-4 w-4" />
                              Заблокировать
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuItem onSelect={() => setResetTarget(user)}>
                            <KeyRound className="mr-2 h-4 w-4" />
                            Сбросить пароль
                          </DropdownMenuItem>
                          {user.role !== "admin" && (
                            <DropdownMenuItem onSelect={() => void handleSetRole(user, "admin")}>
                              <ShieldCheck className="mr-2 h-4 w-4" />
                              Сделать администратором
                            </DropdownMenuItem>
                          )}
                          {user.role === "admin" && (
                            <DropdownMenuItem
                              onSelect={() => void handleSetRole(user, "worker")}
                              disabled={
                                currentUser?.id === user.id ||
                                (adminCount <= 1 && user.role === "admin")
                              }
                            >
                              <ShieldOff className="mr-2 h-4 w-4" />
                              Снять роль администратора
                            </DropdownMenuItem>
                          )}
                        </>
                      )}
                      <DropdownMenuSeparator />
                      <DropdownMenuItem
                        className="text-destructive focus:text-destructive"
                        onSelect={() => router.push(`/dashboard/users/${user.id}/delete`)}
                        disabled={currentUser?.id === user.id}
                      >
                        <Trash2 className="mr-2 h-4 w-4" />
                        Удалить
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </CardHeader>
              <CardContent className="text-sm space-y-2 pt-0 pb-4">
                <div className="flex justify-between items-center gap-4">
                  <span className="text-muted-foreground shrink-0">Email:</span>
                  <span className="font-medium truncate text-right flex-1 opacity-80" title={user.email}>{user.email}</span>
                </div>
                <div className="flex justify-between items-center gap-4">
                  <span className="text-muted-foreground shrink-0">Телефон:</span>
                  <span className="font-medium truncate text-right">{formatPhoneNumberForDisplay(user.phone)}</span>
                </div>
                <Separator className="opacity-20" />
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground flex items-center gap-1.5"><Calendar className="h-3 w-3" /> Добавлен:</span>
                  <span className="font-bold opacity-80">{formatDate(user.createdAt)}</span>
                </div>
              </CardContent>
            </Card>
          ))
        ) : (
          <div className="text-center text-muted-foreground pt-10">
            Пользователи не найдены.
          </div>
        )}
      </div>
      {filteredUsers.length > 0 && <PaginationControls />}

      {isAdmin && currentUser && (
        <>
          <UserBlockDialog
            open={!!blockTarget}
            onOpenChange={(open) => !open && setBlockTarget(null)}
            firestore={firestore}
            target={blockTarget}
            blockedById={currentUser.id}
          />
          <AdminResetPasswordDialog
            open={!!resetTarget}
            onOpenChange={(open) => !open && setResetTarget(null)}
            target={resetTarget}
            getIdToken={getIdToken}
          />
        </>
      )}
    </div>
  );
}
