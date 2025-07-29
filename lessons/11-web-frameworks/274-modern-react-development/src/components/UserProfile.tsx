import React, { useState, useEffect, useCallback, useMemo } from 'react';

// Types
interface User {
  id: number;
  name: string;
  email: string;
  avatar?: string;
  role: 'admin' | 'user';
  createdAt: string;
  isActive: boolean;
}

interface UserProfileProps {
  userId: number;
  onUserUpdate?: (user: User) => void;
  className?: string;
}

interface UseApiResult<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  refetch: () => void;
}

// Custom hook for API calls
function useApi<T>(url: string): UseApiResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Mock data based on URL
      if (url.includes('/users/')) {
        const userId = parseInt(url.split('/').pop() || '1');
        const mockUser: User = {
          id: userId,
          name: `User ${userId}`,
          email: `user${userId}@example.com`,
          avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=user${userId}`,
          role: userId === 1 ? 'admin' : 'user',
          createdAt: new Date().toISOString(),
          isActive: true,
        };
        setData(mockUser as T);
      } else {
        setData([] as T);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, [url]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const refetch = useCallback(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch };
}

// Custom hook for localStorage
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      if (typeof window === 'undefined') return initialValue;
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(`Error reading localStorage key "${key}":`, error);
      return initialValue;
    }
  });

  const setValue = useCallback((value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      if (typeof window !== 'undefined') {
        window.localStorage.setItem(key, JSON.stringify(valueToStore));
      }
    } catch (error) {
      console.error(`Error setting localStorage key "${key}":`, error);
    }
  }, [key, storedValue]);

  return [storedValue, setValue] as const;
}

// Custom hook for debouncing
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// User Profile Component
const UserProfile: React.FC<UserProfileProps> = ({ 
  userId, 
  onUserUpdate, 
  className = '' 
}) => {
  const { data: user, loading, error, refetch } = useApi<User>(`/api/users/${userId}`);
  const [preferences, setPreferences] = useLocalStorage('userPreferences', {
    theme: 'light',
    notifications: true,
  });

  // Memoized computation
  const displayName = useMemo(() => {
    if (!user) return 'Unknown User';
    return `${user.name} (${user.email})`;
  }, [user]);

  // User status badge
  const statusBadge = useMemo(() => {
    if (!user) return null;
    return user.isActive ? (
      <span className="badge badge-success">Active</span>
    ) : (
      <span className="badge badge-warning">Inactive</span>
    );
  }, [user?.isActive]);

  // Callback function with useCallback
  const handleUserUpdate = useCallback((updatedUser: User) => {
    onUserUpdate?.(updatedUser);
    refetch(); // Refresh data
  }, [onUserUpdate, refetch]);

  const handleToggleNotifications = useCallback(() => {
    setPreferences(prev => ({
      ...prev,
      notifications: !prev.notifications,
    }));
  }, [setPreferences]);

  const handleToggleTheme = useCallback(() => {
    setPreferences(prev => ({
      ...prev,
      theme: prev.theme === 'light' ? 'dark' : 'light',
    }));
  }, [setPreferences]);

  if (loading) {
    return (
      <div className={`user-profile loading ${className}`}>
        <div className="skeleton-avatar"></div>
        <div className="skeleton-text"></div>
        <div className="skeleton-text short"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={`user-profile error ${className}`}>
        <div className="error-message">
          <h3>Error loading user</h3>
          <p>{error}</p>
          <button onClick={refetch} className="btn btn-primary">
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className={`user-profile not-found ${className}`}>
        <div className="not-found-message">
          <h3>User not found</h3>
          <p>The requested user could not be found.</p>
        </div>
      </div>
    );
  }

  return (
    <div className={`user-profile ${className}`} data-theme={preferences.theme}>
      <div className="user-profile-header">
        <div className="avatar-section">
          <img 
            src={user.avatar || '/default-avatar.png'} 
            alt={user.name}
            className="user-avatar"
            onError={(e) => {
              e.currentTarget.src = '/default-avatar.png';
            }}
          />
          {statusBadge}
        </div>
        
        <div className="user-info">
          <h2 className="user-name">{displayName}</h2>
          <p className="user-role">Role: {user.role}</p>
          <p className="user-created">
            Member since: {new Date(user.createdAt).toLocaleDateString()}
          </p>
        </div>
      </div>

      <div className="user-profile-body">
        <div className="user-stats">
          <div className="stat-item">
            <span className="stat-label">Profile Views</span>
            <span className="stat-value">1,234</span>
          </div>
          <div className="stat-item">
            <span className="stat-label">Posts</span>
            <span className="stat-value">56</span>
          </div>
          <div className="stat-item">
            <span className="stat-label">Followers</span>
            <span className="stat-value">789</span>
          </div>
        </div>

        <div className="user-preferences">
          <h3>Preferences</h3>
          <div className="preference-item">
            <label>
              <input
                type="checkbox"
                checked={preferences.notifications}
                onChange={handleToggleNotifications}
              />
              Enable Notifications
            </label>
          </div>
          <div className="preference-item">
            <label>
              Theme:
              <select 
                value={preferences.theme} 
                onChange={(e) => setPreferences(prev => ({
                  ...prev,
                  theme: e.target.value as 'light' | 'dark'
                }))}
              >
                <option value="light">Light</option>
                <option value="dark">Dark</option>
              </select>
            </label>
          </div>
        </div>

        <div className="user-actions">
          <button 
            onClick={() => handleUserUpdate(user)} 
            className="btn btn-primary"
          >
            Update Profile
          </button>
          <button 
            onClick={refetch} 
            className="btn btn-secondary"
          >
            Refresh Data
          </button>
          {user.role === 'admin' && (
            <button className="btn btn-warning">
              Admin Settings
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

// Search Input Component with debouncing
interface SearchInputProps {
  onSearch: (query: string) => void;
  placeholder?: string;
  debounceMs?: number;
}

const SearchInput: React.FC<SearchInputProps> = ({
  onSearch,
  placeholder = "Search...",
  debounceMs = 300,
}) => {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, debounceMs);

  useEffect(() => {
    onSearch(debouncedQuery);
  }, [debouncedQuery, onSearch]);

  return (
    <div className="search-input">
      <input
        type="text"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder={placeholder}
        className="search-field"
      />
      {query && (
        <button
          onClick={() => setQuery('')}
          className="clear-button"
          aria-label="Clear search"
        >
          ×
        </button>
      )}
    </div>
  );
};

// Example usage component
const UserProfileExample: React.FC = () => {
  const [selectedUserId, setSelectedUserId] = useState(1);
  const [searchResults, setSearchResults] = useState<string[]>([]);

  const handleUserUpdate = useCallback((user: User) => {
    console.log('User updated:', user);
    alert(`User ${user.name} has been updated!`);
  }, []);

  const handleSearch = useCallback((query: string) => {
    // Simulate search results
    if (query.trim()) {
      const mockResults = [
        `Result 1 for "${query}"`,
        `Result 2 for "${query}"`,
        `Result 3 for "${query}"`,
      ];
      setSearchResults(mockResults);
    } else {
      setSearchResults([]);
    }
  }, []);

  return (
    <div className="app">
      <h1>Modern React Components Example</h1>
      
      <div className="controls">
        <label>
          Select User ID:
          <select 
            value={selectedUserId} 
            onChange={(e) => setSelectedUserId(Number(e.target.value))}
          >
            {[1, 2, 3, 4, 5].map(id => (
              <option key={id} value={id}>User {id}</option>
            ))}
          </select>
        </label>
      </div>

      <div className="search-section">
        <h2>Search Example</h2>
        <SearchInput onSearch={handleSearch} placeholder="Search users..." />
        {searchResults.length > 0 && (
          <ul className="search-results">
            {searchResults.map((result, index) => (
              <li key={index}>{result}</li>
            ))}
          </ul>
        )}
      </div>

      <div className="user-section">
        <h2>User Profile</h2>
        <UserProfile
          userId={selectedUserId}
          onUserUpdate={handleUserUpdate}
          className="main-profile"
        />
      </div>
    </div>
  );
};

export default UserProfileExample;
export { UserProfile, SearchInput, useApi, useLocalStorage, useDebounce };
