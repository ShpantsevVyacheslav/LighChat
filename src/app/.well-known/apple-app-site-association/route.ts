import { NextResponse } from 'next/server';

/**
 * Apple Universal Links — см. https://developer.apple.com/documentation/xcode/supporting-associated-domains
 * Bundle ID: mobile/app/ios (PRODUCT_BUNDLE_IDENTIFIER).
 * Team ID: Xcode DEVELOPMENT_TEAM.
 */
const APPLE_TEAM_ID = 'T896C2B2FW';
const IOS_BUNDLE_ID = 'com.lighchat.lighchatMobile';

export async function GET() {
  const body = {
    applinks: {
      apps: [] as string[],
      details: [
        {
          appID: `${APPLE_TEAM_ID}.${IOS_BUNDLE_ID}`,
          paths: ['/meetings/*'],
        },
      ],
    },
  };

  return NextResponse.json(body, {
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'public, max-age=3600',
    },
  });
}
