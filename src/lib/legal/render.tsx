import * as React from 'react';

type Block =
  | { type: 'heading'; level: 1 | 2 | 3 | 4; text: string }
  | { type: 'paragraph'; text: string }
  | { type: 'blockquote'; text: string }
  | { type: 'list'; ordered: boolean; items: string[] }
  | { type: 'table'; header: string[]; rows: string[][] }
  | { type: 'hr' };

const HEADING_RE = /^(#{1,4})\s+(.+)$/;
const LIST_UL_RE = /^\s*[-*]\s+(.+)$/;
const LIST_OL_RE = /^\s*\d+\.\s+(.+)$/;
const TABLE_SEP_RE = /^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)+\|?\s*$/;
const HR_RE = /^\s*-{3,}\s*$/;
const BLOCKQUOTE_RE = /^>\s?(.*)$/;

function parseBlocks(md: string): Block[] {
  const lines = md.replace(/\r\n/g, '\n').split('\n');
  const out: Block[] = [];
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];

    if (line.trim() === '') {
      i++;
      continue;
    }

    if (HR_RE.test(line)) {
      out.push({ type: 'hr' });
      i++;
      continue;
    }

    const headingMatch = HEADING_RE.exec(line);
    if (headingMatch) {
      out.push({
        type: 'heading',
        level: Math.min(4, headingMatch[1].length) as 1 | 2 | 3 | 4,
        text: headingMatch[2].trim(),
      });
      i++;
      continue;
    }

    if (BLOCKQUOTE_RE.test(line)) {
      const buf: string[] = [];
      while (i < lines.length && BLOCKQUOTE_RE.test(lines[i])) {
        const m = BLOCKQUOTE_RE.exec(lines[i]);
        buf.push(m ? m[1] : '');
        i++;
      }
      out.push({ type: 'blockquote', text: buf.join(' ').trim() });
      continue;
    }

    if (LIST_UL_RE.test(line) || LIST_OL_RE.test(line)) {
      const ordered = LIST_OL_RE.test(line);
      const items: string[] = [];
      const re = ordered ? LIST_OL_RE : LIST_UL_RE;
      while (i < lines.length && re.test(lines[i])) {
        const m = re.exec(lines[i]);
        items.push(m ? m[1].trim() : '');
        i++;
      }
      out.push({ type: 'list', ordered, items });
      continue;
    }

    if (line.trim().startsWith('|') && i + 1 < lines.length && TABLE_SEP_RE.test(lines[i + 1])) {
      const header = splitRow(line);
      i += 2;
      const rows: string[][] = [];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        rows.push(splitRow(lines[i]));
        i++;
      }
      out.push({ type: 'table', header, rows });
      continue;
    }

    const buf: string[] = [];
    while (
      i < lines.length &&
      lines[i].trim() !== '' &&
      !HEADING_RE.test(lines[i]) &&
      !LIST_UL_RE.test(lines[i]) &&
      !LIST_OL_RE.test(lines[i]) &&
      !BLOCKQUOTE_RE.test(lines[i]) &&
      !HR_RE.test(lines[i]) &&
      !lines[i].trim().startsWith('|')
    ) {
      buf.push(lines[i]);
      i++;
    }
    out.push({ type: 'paragraph', text: buf.join(' ').trim() });
  }

  return out;
}

function splitRow(line: string): string[] {
  const trimmed = line.trim().replace(/^\|/, '').replace(/\|$/, '');
  return trimmed.split('|').map((c) => c.trim());
}

function renderInline(text: string, keyPrefix: string): React.ReactNode[] {
  const tokens: React.ReactNode[] = [];
  const linkRe = /\[([^\]]+)\]\(([^)]+)\)/g;
  const parts: { text: string; isLink: boolean; href?: string }[] = [];
  let cursor = 0;
  let m: RegExpExecArray | null;
  while ((m = linkRe.exec(text)) !== null) {
    if (m.index > cursor) parts.push({ text: text.slice(cursor, m.index), isLink: false });
    parts.push({ text: m[1], isLink: true, href: m[2] });
    cursor = m.index + m[0].length;
  }
  if (cursor < text.length) parts.push({ text: text.slice(cursor), isLink: false });

  parts.forEach((part, idx) => {
    const key = `${keyPrefix}-${idx}`;
    if (part.isLink) {
      const isExternal = /^https?:/.test(part.href || '');
      tokens.push(
        <a
          key={key}
          href={part.href}
          {...(isExternal ? { target: '_blank', rel: 'noreferrer noopener' } : {})}
          className="text-primary underline-offset-2 hover:underline"
        >
          {renderEmphasis(part.text, `${key}-em`)}
        </a>
      );
    } else {
      tokens.push(...renderEmphasis(part.text, key));
    }
  });

  return tokens;
}

function renderEmphasis(text: string, keyPrefix: string): React.ReactNode[] {
  const out: React.ReactNode[] = [];
  const re = /(\*\*([^*]+)\*\*|`([^`]+)`)/g;
  let cursor = 0;
  let m: RegExpExecArray | null;
  let idx = 0;
  while ((m = re.exec(text)) !== null) {
    if (m.index > cursor) out.push(text.slice(cursor, m.index));
    const key = `${keyPrefix}-${idx++}`;
    if (m[2] !== undefined) {
      out.push(<strong key={key}>{m[2]}</strong>);
    } else if (m[3] !== undefined) {
      out.push(
        <code key={key} className="rounded bg-muted px-1 py-0.5 text-[0.85em]">
          {m[3]}
        </code>
      );
    }
    cursor = m.index + m[0].length;
  }
  if (cursor < text.length) out.push(text.slice(cursor));
  return out;
}

export function renderMarkdown(md: string): React.ReactNode {
  const blocks = parseBlocks(md);
  return blocks.map((block, idx) => {
    const key = `b-${idx}`;
    switch (block.type) {
      case 'heading': {
        const Tag = (`h${block.level}` as 'h1' | 'h2' | 'h3' | 'h4');
        const cls =
          block.level === 1
            ? 'mt-8 mb-4 text-3xl font-bold tracking-tight'
            : block.level === 2
              ? 'mt-8 mb-3 text-2xl font-semibold tracking-tight'
              : block.level === 3
                ? 'mt-6 mb-2 text-xl font-semibold'
                : 'mt-4 mb-2 text-lg font-semibold';
        return (
          <Tag key={key} className={cls}>
            {renderInline(block.text, key)}
          </Tag>
        );
      }
      case 'paragraph':
        return (
          <p key={key} className="mb-4 leading-relaxed text-foreground/90">
            {renderInline(block.text, key)}
          </p>
        );
      case 'blockquote':
        return (
          <blockquote
            key={key}
            className="mb-4 border-l-4 border-primary/40 bg-primary/5 px-4 py-3 text-sm text-foreground/80"
          >
            {renderInline(block.text, key)}
          </blockquote>
        );
      case 'list': {
        const ListTag = block.ordered ? 'ol' : 'ul';
        const cls = block.ordered
          ? 'mb-4 ml-6 list-decimal space-y-1'
          : 'mb-4 ml-6 list-disc space-y-1';
        return (
          <ListTag key={key} className={cls}>
            {block.items.map((it, i) => (
              <li key={`${key}-${i}`} className="leading-relaxed">
                {renderInline(it, `${key}-${i}`)}
              </li>
            ))}
          </ListTag>
        );
      }
      case 'table':
        return (
          <div key={key} className="mb-4 overflow-x-auto rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead className="bg-muted/60">
                <tr>
                  {block.header.map((h, i) => (
                    <th key={`${key}-h-${i}`} className="px-3 py-2 text-left font-semibold">
                      {renderInline(h, `${key}-h-${i}`)}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {block.rows.map((row, ri) => (
                  <tr key={`${key}-r-${ri}`} className="border-t border-border">
                    {row.map((cell, ci) => (
                      <td key={`${key}-r-${ri}-${ci}`} className="px-3 py-2 align-top">
                        {renderInline(cell, `${key}-r-${ri}-${ci}`)}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        );
      case 'hr':
        return <hr key={key} className="my-8 border-border" />;
    }
  });
}
