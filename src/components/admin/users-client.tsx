"use client";

import { useState, useMemo, useCallback } from "react";
import { useRouter } from "next/navigation";
import type { User, UserRole } from "@/lib/types";
import { useAuth } from "@/hooks/use-auth";
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
  Monitor,
} from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { userAvatarListUrl } from "@/lib/user-avatar-display";
import { formatPhoneNumberForDisplay } from "@/lib/phone-utils";
import { Card, CardHeader, CardTitle, CardContent } from "../ui/card";
import { useAuth as useFirebaseAuth, useFirestore, useCollection, useMemoFirebase } from "@/firebase";
import { collection, deleteField, doc, query, updateDoc } from "firebase/firestore";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { format, parseISO } from "date-fns";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import { UserBlockDialog } from "@/components/admin/user-block-dialog";
import { AdminResetPasswordDialog } from "@/components/admin/admin-reset-password-dialog";
import { AdminUserSessionsDialog } from "@/components/admin/admin-user-sessions-dialog";
import { isAccountBlocked } from "@/lib/account-block-utils";
import { useToast } from "@/hooks/use-toast";
import { ruEnSubstringMatch } from "@/lib/ru-latin-search-normalize";
import { useI18n } from "@/hooks/use-i18n";
import { useDateFnsLocale } from "@/hooks/use-date-fns-locale";

interface UsersClientProps {
  /** Скрыть верхний заголовок страницы (вкладка админки). */
  embedded?: boolean;
}

export function UsersClient({ embedded = false }: UsersClientProps) {
  const firestore = useFirestore();
  const firebaseAuth = useFirebaseAuth();
  const { user: currentUser } = useAuth();
  const { toast } = useToast();
  const { t } = useI18n();
  const dateFnsLocale = useDateFnsLocale();
  const [searchTerm, setSearchTerm] = useState("");
  const [blockTarget, setBlockTarget] = useState<User | null>(null);
  const [resetTarget, setResetTarget] = useState<User | null>(null);
  const [sessionsTarget, setSessionsTarget] = useState<User | null>(null);
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
      toast({ title: t("admin.usersList.toastUnblockedTitle") });
    } catch (e) {
      console.error(e);
      toast({ variant: "destructive", title: t("admin.usersList.toastUnblockErrorTitle") });
    }
  };

  const handleSetRole = async (user: User, role: UserRole) => {
    if (!firestore) return;
    if (user.role === "admin" && role === "worker" && adminCount <= 1) {
      toast({ variant: "destructive", title: t("admin.usersList.toastLastAdminErrorTitle") });
      return;
    }
    try {
      await updateDoc(doc(firestore, "users", user.id), { role });
      toast({
        title: role === "admin" ? t("admin.usersList.toastRoleAdminTitle") : t("admin.usersList.toastRoleWorkerTitle"),
      });
    } catch (e) {
      console.error(e);
      toast({ variant: "destructive", title: t("admin.usersList.toastRoleErrorTitle") });
    }
  };

  const filteredUsers = useMemo(() => (users || [])
    .filter(user => !user.deletedAt)
    .filter((user) =>
        ruEnSubstringMatch(user.name ?? "", searchTerm) ||
        ruEnSubstringMatch(user.email ?? "", searchTerm) ||
        (user.phone && user.phone.includes(searchTerm))
  ), [users, searchTerm]);

  const toTime = (val: unknown) => {
    if (!val) return 0;
    if (
      typeof val === 'object' &&
      val != null &&
      'toDate' in val &&
      typeof (val as { toDate?: unknown }).toDate === 'function'
    ) {
      return (val as { toDate: () => Date }).toDate().getTime();
    }
    if (typeof val === 'string') {
        try {
            return parseISO(val).getTime();
        } catch {
            return new Date(val).getTime();
        }
    }
    return new Date(val as never).getTime();
  };

  /** Сравнение значений сортировки без «unknown < unknown» (строгий TS). */
  const compareSortPair = (a: unknown, b: unknown): number => {
    if (typeof a === 'number' && typeof b === 'number') {
      if (a === b) return 0;
      return a < b ? -1 : 1;
    }
    const sa = String(a ?? '');
    const sb = String(b ?? '');
    if (sa === sb) return 0;
    return sa < sb ? -1 : 1;
  };

  const sortedUsers = useMemo(() => {
    const sortableItems = [...filteredUsers];
    if (sortConfig !== null) {
      sortableItems.sort((a, b) => {
        let aVal: unknown;
        let bVal: unknown;

        switch (sortConfig.key) {
          case 'name':
            aVal = a.name.toLowerCase();
            bVal = b.name.toLowerCase();
            break;
          case 'role':
            aVal = (a.role ? (a.role === "admin" ? t("admin.roles.admin") : t("admin.roles.worker")) : "").toLowerCase();
            bVal = (b.role ? (b.role === "admin" ? t("admin.roles.admin") : t("admin.roles.worker")) : "").toLowerCase();
            break;
          case 'createdAt':
            aVal = toTime(a.createdAt);
            bVal = toTime(b.createdAt);
            break;
          default:
            aVal = (a as Record<string, unknown>)[sortConfig.key];
            bVal = (b as Record<string, unknown>)[sortConfig.key];
        }

        const base = compareSortPair(aVal, bVal);
        return sortConfig.direction === 'asc' ? base : -base;
      });
    }
    return sortableItems;
  }, [filteredUsers, sortConfig, t]);

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
            <span className="text-sm text-muted-foreground">{t("admin.usersList.perPage")}</span>
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
                {t("admin.usersList.pageOf", { current: currentPage, total: totalPages })}
            </span>
            <div className="flex items-center gap-2">
                <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1 || isUsersLoading} className="rounded-full">
                    {t("admin.usersList.back")}
                </Button>
                <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages || isUsersLoading} className="rounded-full">
                    {t("admin.usersList.forward")}
                </Button>
            </div>
        </div>
    </div>
  );

  const formatDate = useCallback(
    (dateVal: unknown) => {
      if (!dateVal) return t("admin.usersList.dash");
      try {
        const date =
          typeof (dateVal as { toDate?: () => Date }).toDate === "function"
            ? (dateVal as { toDate: () => Date }).toDate()
            : typeof dateVal === "string"
              ? parseISO(dateVal)
              : new Date(dateVal as string | number);
        return format(date, "dd.MM.yyyy", { locale: dateFnsLocale });
      } catch {
        return t("admin.usersList.dash");
      }
    },
    [t, dateFnsLocale],
  );

  return (
    <div className="space-y-6">
      {!embedded && (
        <div className="animate-in fade-in slide-in-from-top-4 duration-700 flex items-center gap-2">
          <div className="min-w-0">
            <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 leading-tight">
              <UserCog className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> {t("admin.usersList.title")}
            </h1>
            <p className="text-xs sm:text-sm text-muted-foreground">{t("admin.usersList.subtitle")}</p>
          </div>
        </div>
      )}

      <div className="flex items-center justify-between gap-4">
        <Input
          placeholder={t("admin.usersList.searchPlaceholder")}
          value={searchTerm}
          tabIndex={-1}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full max-w-lg rounded-full"
        />
        <Button onClick={() => router.push('/dashboard/users/new')} size="icon" aria-label={t("admin.usersList.addUserAria")} className="rounded-full shadow-lg shadow-primary/20">
            <PlusCircle className="h-4 w-4" />
        </Button>
      </div>
      <div className="rounded-xl border hidden md:block overflow-hidden bg-white/50 dark:bg-black/20">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>
                <Button variant="ghost" onClick={() => handleSort('name')} className="hover:bg-transparent p-0 font-semibold h-auto">
                  {t("admin.usersList.colUser")} <ArrowUpDown className="ml-2 h-4 w-4" />
                </Button>
              </TableHead>
              <TableHead>{t("admin.usersList.colEmail")}</TableHead>
              <TableHead>{t("admin.usersList.colPhone")}</TableHead>
              <TableHead>
                <Button variant="ghost" onClick={() => handleSort('role')} className="hover:bg-transparent p-0 font-semibold h-auto">
                  {t("admin.usersList.colRole")} <ArrowUpDown className="ml-2 h-4 w-4" />
                </Button>
              </TableHead>
              <TableHead>
                <Button variant="ghost" onClick={() => handleSort('createdAt')} className="hover:bg-transparent p-0 font-semibold h-auto">
                  {t("admin.usersList.colAdded")} <ArrowUpDown className="ml-2 h-4 w-4" />
                </Button>
              </TableHead>
              <TableHead><span className="sr-only">{t("admin.usersList.colActionsSr")}</span></TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isUsersLoading ? (
              <TableRow>
                <TableCell colSpan={6} className="h-24 text-center">
                  <Loader2 className="mx-auto h-6 w-6 animate-spin text-primary" />
                  <p className="mt-2 text-muted-foreground">{t("admin.usersList.loading")}</p>
                </TableCell>
              </TableRow>
            ) : paginatedUsers.length > 0 ? (
              paginatedUsers.map((user) => (
                <TableRow key={user.id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                        <Avatar className="border border-white/10 shadow-sm">
                            <AvatarImage src={userAvatarListUrl(user)} alt={user.name} className="object-cover" />
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
                        {user.role ? (user.role === "admin" ? t("admin.roles.admin") : t("admin.roles.worker")) : t("admin.usersList.dash")}
                      </Badge>
                      {isAccountBlocked(user) && (
                        <Badge variant="destructive" className="rounded-full text-xs">
                          {t("admin.usersList.blocked")}
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
                            <span className="sr-only">{t("admin.usersList.openMenuSr")}</span>
                            <MoreHorizontal className="h-4 w-4" />
                        </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end" className="rounded-xl shadow-2xl border-none">
                        <DropdownMenuItem onSelect={() => router.push(`/dashboard/users/${user.id}/edit`)}>
                            <Edit className="mr-2 h-4 w-4" />
                            {t("admin.usersList.edit")}
                        </DropdownMenuItem>
                        {isAdmin && (
                          <>
                            <DropdownMenuSeparator />
                            {isAccountBlocked(user) ? (
                              <DropdownMenuItem onSelect={() => void handleUnblock(user)}>
                                <ShieldOff className="mr-2 h-4 w-4" />
                                {t("admin.usersList.unblock")}
                              </DropdownMenuItem>
                            ) : (
                              <DropdownMenuItem
                                onSelect={() => setBlockTarget(user)}
                                disabled={currentUser?.id === user.id}
                              >
                                <Ban className="mr-2 h-4 w-4" />
                                {t("admin.usersList.block")}
                              </DropdownMenuItem>
                            )}
                            <DropdownMenuItem onSelect={() => setResetTarget(user)}>
                              <KeyRound className="mr-2 h-4 w-4" />
                              {t("admin.usersList.resetPassword")}
                            </DropdownMenuItem>
                            <DropdownMenuItem onSelect={() => setSessionsTarget(user)}>
                              <Monitor className="mr-2 h-4 w-4" />
                              Сессии
                            </DropdownMenuItem>
                            {user.role !== "admin" && (
                              <DropdownMenuItem onSelect={() => void handleSetRole(user, "admin")}>
                                <ShieldCheck className="mr-2 h-4 w-4" />
                                {t("admin.usersList.makeAdmin")}
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
                                {t("admin.usersList.removeAdmin")}
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
                            {t("admin.usersList.delete")}
                        </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={6} className="h-24 text-center">
                  {t("admin.usersList.empty")}
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
                <p className="mt-2">{t("admin.usersList.loading")}</p>
            </div>
        ) : paginatedUsers.length > 0 ? (
          paginatedUsers.map((user) => (
            <Card key={user.id} className="w-full rounded-3xl overflow-hidden border-white/10 shadow-lg">
              <CardHeader className="pb-3">
                <div className="flex justify-between items-start gap-2">
                  <div className="flex items-center gap-3 min-w-0">
                    <Avatar className="shrink-0 border border-white/10 shadow-sm">
                      <AvatarImage src={userAvatarListUrl(user)} alt={user.name} className="object-cover" />
                      <AvatarFallback>{user.name.charAt(0)}</AvatarFallback>
                    </Avatar>
                    <div className="min-w-0">
                      <CardTitle className="text-base leading-tight truncate">{user.name}</CardTitle>
                      <div className="mt-0.5 flex flex-wrap items-center gap-1">
                        <p className="text-[10px] uppercase font-bold text-primary tracking-wider">
                          {user.role ? (user.role === "admin" ? t("admin.roles.admin") : t("admin.roles.worker")) : t("admin.usersList.dash")}
                        </p>
                        {isAccountBlocked(user) && (
                          <Badge variant="destructive" className="rounded-full px-1.5 py-0 text-[9px]">
                            {t("admin.usersList.blocked")}
                          </Badge>
                        )}
                      </div>
                    </div>
                  </div>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" className="h-8 w-8 p-0 shrink-0 rounded-full">
                        <span className="sr-only">{t("admin.usersList.openMenuSr")}</span>
                        <MoreHorizontal className="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end" className="rounded-xl shadow-2xl border-none">
                      <DropdownMenuItem onSelect={() => router.push(`/dashboard/users/${user.id}/edit`)}>
                        <Edit className="mr-2 h-4 w-4" />
                        {t("admin.usersList.edit")}
                      </DropdownMenuItem>
                      {isAdmin && (
                        <>
                          <DropdownMenuSeparator />
                          {isAccountBlocked(user) ? (
                            <DropdownMenuItem onSelect={() => void handleUnblock(user)}>
                              <ShieldOff className="mr-2 h-4 w-4" />
                              {t("admin.usersList.unblock")}
                            </DropdownMenuItem>
                          ) : (
                            <DropdownMenuItem
                              onSelect={() => setBlockTarget(user)}
                              disabled={currentUser?.id === user.id}
                            >
                              <Ban className="mr-2 h-4 w-4" />
                              {t("admin.usersList.block")}
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuItem onSelect={() => setResetTarget(user)}>
                            <KeyRound className="mr-2 h-4 w-4" />
                            {t("admin.usersList.resetPassword")}
                          </DropdownMenuItem>
                          {user.role !== "admin" && (
                            <DropdownMenuItem onSelect={() => void handleSetRole(user, "admin")}>
                              <ShieldCheck className="mr-2 h-4 w-4" />
                              {t("admin.usersList.makeAdmin")}
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
                              {t("admin.usersList.removeAdmin")}
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
                        {t("admin.usersList.delete")}
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </CardHeader>
              <CardContent className="text-sm space-y-2 pt-0 pb-4">
                <div className="flex justify-between items-center gap-4">
                  <span className="text-muted-foreground shrink-0">{t("admin.usersList.mobileEmailLabel")}</span>
                  <span className="font-medium truncate text-right flex-1 opacity-80" title={user.email}>{user.email}</span>
                </div>
                <div className="flex justify-between items-center gap-4">
                  <span className="text-muted-foreground shrink-0">{t("admin.usersList.mobilePhoneLabel")}</span>
                  <span className="font-medium truncate text-right">{formatPhoneNumberForDisplay(user.phone)}</span>
                </div>
                <Separator className="opacity-20" />
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground flex items-center gap-1.5"><Calendar className="h-3 w-3" /> {t("admin.usersList.mobileAddedLabel")}</span>
                  <span className="font-bold opacity-80">{formatDate(user.createdAt)}</span>
                </div>
              </CardContent>
            </Card>
          ))
        ) : (
          <div className="text-center text-muted-foreground pt-10">
            {t("admin.usersList.empty")}
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
          {sessionsTarget && (
            <AdminUserSessionsDialog
              open={!!sessionsTarget}
              onOpenChange={(open) => !open && setSessionsTarget(null)}
              targetUserId={sessionsTarget.id}
              targetUserName={sessionsTarget.name}
            />
          )}
        </>
      )}
    </div>
  );
}
