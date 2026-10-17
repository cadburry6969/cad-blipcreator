import type { PermissionOption } from '../../types';

export type SourceFilter = 'all' | 'saved' | 'scripts';

export interface Filters {
  search: string;
  source: SourceFilter;
  /** a permission value, or 'any' */
  permission: string;
}

const SOURCE_TABS: { value: SourceFilter; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'saved', label: 'Saved' },
  { value: 'scripts', label: 'From scripts' },
];

interface ListFiltersProps {
  filters: Filters;
  permissions: PermissionOption[];
  onChange: (filters: Filters) => void;
}

export function ListFilters({ filters, permissions, onChange }: ListFiltersProps) {
  return (
    <div className="filters">
      <input
        className="input"
        placeholder="Search blips"
        value={filters.search}
        onChange={(e) => onChange({ ...filters, search: e.target.value })}
      />
      <div className="filters__row">
        <div className="tabs">
          {SOURCE_TABS.map((tab) => (
            <button
              key={tab.value}
              className={`tabs__tab${filters.source === tab.value ? ' tabs__tab--active' : ''}`}
              onClick={() => onChange({ ...filters, source: tab.value })}
            >
              {tab.label}
            </button>
          ))}
        </div>
        <select
          className="input input--compact"
          value={filters.permission}
          onChange={(e) => onChange({ ...filters, permission: e.target.value })}
        >
          <option value="any">Any permission</option>
          {permissions.map((permission) => (
            <option key={permission.value} value={permission.value}>
              {permission.label}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}
