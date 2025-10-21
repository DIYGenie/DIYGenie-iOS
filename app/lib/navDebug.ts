type NavLike = {
  getState?: () => any;
  getParent?: (id?: string) => any;
};

export function logNavTree(navigation: NavLike, label: string) {
  try {
    const parentRootTabs = navigation.getParent?.('root-tabs');
    const parentAny = navigation.getParent?.();

    const fmt = (nav: any) => {
      const st = nav?.getState?.();
      if (!st) return '(no state)';
      const routeNames = (st.routes || []).map((r: any) => r.name);
      return JSON.stringify(
        {
          type: st.type,
          index: st.index,
          routes: routeNames,
          current: st.routes?.[st.index || 0]?.name,
        },
        null,
        2
      );
    };

    const currentState = navigation.getState?.();

    // ⬇️ NEW: peek into the Projects tab's child state (to discover its stack root)
    const parent = parentRootTabs || parentAny;
    const parentState = parent?.getState?.();
    let projectsChild: any = '(no projects child)';
    if (parentState?.routes) {
      const projectsRoute = parentState.routes.find((r: any) => r.name === 'Projects');
      const child = projectsRoute?.state;
      if (child?.routes) {
        projectsChild = {
          type: child.type,
          index: child.index,
          routes: child.routes.map((r: any) => r.name),
          current: child.routes?.[child.index || 0]?.name,
        };
      }
    }

    console.log('NAV DEBUG ::', label, {
      current: {
        index: currentState?.index,
        routes: (currentState?.routes || []).map((r: any) => r.name),
        current: currentState?.routes?.[currentState?.index || 0]?.name,
      },
      parent_root_tabs: fmt(parentRootTabs),
      parent_any: fmt(parentAny),
      projects_child: projectsChild, // ⬅️ shows true root name we should navigate to
    });
  } catch (e) {
    console.log('NAV DEBUG ERROR ::', label, String(e));
  }
}
