// GENERATED FILE: do not edit by hand. Run `pnpm gen:types` to regenerate.

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      activities: {
        Row: {
          created_at: string;
          distance_m: number;
          duration_s: number;
          ended_at: string;
          id: string;
          source: string | null;
          source_workout_id: string;
          sport: Database['public']['Enums']['sport'];
          started_at: string;
          synced_at: string;
          updated_at: string;
          user_entered: boolean;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          distance_m: number;
          duration_s: number;
          ended_at: string;
          id?: string;
          source?: string | null;
          source_workout_id: string;
          sport: Database['public']['Enums']['sport'];
          started_at: string;
          synced_at?: string;
          updated_at?: string;
          user_entered?: boolean;
          user_id: string;
        };
        Update: {
          created_at?: string;
          distance_m?: number;
          duration_s?: number;
          ended_at?: string;
          id?: string;
          source?: string | null;
          source_workout_id?: string;
          sport?: Database['public']['Enums']['sport'];
          started_at?: string;
          synced_at?: string;
          updated_at?: string;
          user_entered?: boolean;
          user_id?: string;
        };
        Relationships: [];
      };
      cards: {
        Row: {
          activity_id: string | null;
          created_at: string;
          id: string;
          image_hash: string | null;
          kind: Database['public']['Enums']['card_kind'];
          round_id: string | null;
          rule_version: number;
          serial: number;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          activity_id?: string | null;
          created_at?: string;
          id?: string;
          image_hash?: string | null;
          kind: Database['public']['Enums']['card_kind'];
          round_id?: string | null;
          rule_version: number;
          serial?: never;
          user_id: string;
        };
        Update: {
          activity_id?: string | null;
          created_at?: string;
          id?: string;
          image_hash?: string | null;
          kind?: Database['public']['Enums']['card_kind'];
          round_id?: string | null;
          rule_version?: number;
          serial?: never;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'cards_activity_id_fkey';
            columns: ['activity_id'];
            isOneToOne: false;
            referencedRelation: 'activities';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'cards_round_id_fkey';
            columns: ['round_id'];
            isOneToOne: false;
            referencedRelation: 'rounds';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'cards_user_id_fkey';
            columns: ['user_id'];
            isOneToOne: false;
            referencedRelation: 'profiles';
            referencedColumns: ['id'];
          },
        ];
      };
      checkins: {
        Row: {
          created_at: string;
          day: string;
          id: string;
          photo_path: string;
          round_id: string;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          day: string;
          id?: string;
          photo_path: string;
          round_id: string;
          user_id: string;
        };
        Update: {
          created_at?: string;
          day?: string;
          id?: string;
          photo_path?: string;
          round_id?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'checkins_round_id_fkey';
            columns: ['round_id'];
            isOneToOne: false;
            referencedRelation: 'rounds';
            referencedColumns: ['id'];
          },
        ];
      };
      daily_points: {
        Row: {
          computed_at: string;
          counted_ride_metres: number;
          day: string;
          flags: Database['public']['Enums']['point_flag'][];
          movement_centipoints: number;
          photo_centipoints: number;
          round_id: string;
          rule_version: number;
          total_centipoints: number | null;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          computed_at?: string;
          counted_ride_metres?: number;
          day: string;
          flags?: Database['public']['Enums']['point_flag'][];
          movement_centipoints: number;
          photo_centipoints: number;
          round_id: string;
          rule_version: number;
          total_centipoints?: never;
          user_id: string;
        };
        Update: {
          computed_at?: string;
          counted_ride_metres?: number;
          day?: string;
          flags?: Database['public']['Enums']['point_flag'][];
          movement_centipoints?: number;
          photo_centipoints?: number;
          round_id?: string;
          rule_version?: number;
          total_centipoints?: never;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'daily_points_round_id_fkey';
            columns: ['round_id'];
            isOneToOne: false;
            referencedRelation: 'rounds';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'daily_points_user_id_fkey';
            columns: ['user_id'];
            isOneToOne: false;
            referencedRelation: 'profiles';
            referencedColumns: ['id'];
          },
        ];
      };
      daily_step_summaries: {
        Row: {
          created_at: string;
          day: string;
          id: string;
          round_id: string;
          source: string | null;
          steps: number;
          synced_at: string;
          updated_at: string;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          day: string;
          id?: string;
          round_id: string;
          source?: string | null;
          steps: number;
          synced_at?: string;
          updated_at?: string;
          user_id: string;
        };
        Update: {
          created_at?: string;
          day?: string;
          id?: string;
          round_id?: string;
          source?: string | null;
          steps?: number;
          synced_at?: string;
          updated_at?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'daily_step_summaries_round_id_fkey';
            columns: ['round_id'];
            isOneToOne: false;
            referencedRelation: 'rounds';
            referencedColumns: ['id'];
          },
        ];
      };
      disputes: {
        Row: {
          created_at: string;
          id: string;
          opened_by: string;
          reason: string;
          round_id: string;
          status: Database['public']['Enums']['dispute_status'];
          target_id: string;
          target_type: Database['public']['Enums']['dispute_target'];
          updated_at: string;
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          id?: string;
          opened_by: string;
          reason: string;
          round_id: string;
          status?: Database['public']['Enums']['dispute_status'];
          target_id: string;
          target_type: Database['public']['Enums']['dispute_target'];
          updated_at?: string;
        };
        Update: {
          created_at?: string;
          id?: string;
          opened_by?: string;
          reason?: string;
          round_id?: string;
          status?: Database['public']['Enums']['dispute_status'];
          target_id?: string;
          target_type?: Database['public']['Enums']['dispute_target'];
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'disputes_opened_by_fkey';
            columns: ['opened_by'];
            isOneToOne: false;
            referencedRelation: 'profiles';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'disputes_round_id_fkey';
            columns: ['round_id'];
            isOneToOne: false;
            referencedRelation: 'rounds';
            referencedColumns: ['id'];
          },
        ];
      };
      invites: {
        Row: {
          code: string;
          created_at: string;
          created_by: string;
          expires_at: string;
          id: string;
          party_id: string;
          revoked_at: string | null;
        };
        ComputedFields: never;
        Insert: {
          code: string;
          created_at?: string;
          created_by: string;
          expires_at: string;
          id?: string;
          party_id: string;
          revoked_at?: string | null;
        };
        Update: {
          code?: string;
          created_at?: string;
          created_by?: string;
          expires_at?: string;
          id?: string;
          party_id?: string;
          revoked_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'invites_created_by_fkey';
            columns: ['created_by'];
            isOneToOne: false;
            referencedRelation: 'profiles';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'invites_party_id_fkey';
            columns: ['party_id'];
            isOneToOne: false;
            referencedRelation: 'parties';
            referencedColumns: ['id'];
          },
        ];
      };
      memberships: {
        Row: {
          id: string;
          joined_at: string;
          left_at: string | null;
          party_id: string;
          rating: number;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          id?: string;
          joined_at?: string;
          left_at?: string | null;
          party_id: string;
          rating?: number;
          user_id: string;
        };
        Update: {
          id?: string;
          joined_at?: string;
          left_at?: string | null;
          party_id?: string;
          rating?: number;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'memberships_party_id_fkey';
            columns: ['party_id'];
            isOneToOne: false;
            referencedRelation: 'parties';
            referencedColumns: ['id'];
          },
        ];
      };
      parties: {
        Row: {
          created_at: string;
          created_by: string;
          id: string;
          name: string;
          timezone: string;
          updated_at: string;
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          created_by: string;
          id?: string;
          name: string;
          timezone?: string;
          updated_at?: string;
        };
        Update: {
          created_at?: string;
          created_by?: string;
          id?: string;
          name?: string;
          timezone?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'parties_created_by_fkey';
            columns: ['created_by'];
            isOneToOne: false;
            referencedRelation: 'profiles';
            referencedColumns: ['id'];
          },
        ];
      };
      profiles: {
        Row: {
          avatar_path: string | null;
          created_at: string;
          deleted_at: string | null;
          display_name: string;
          id: string;
          updated_at: string;
        };
        ComputedFields: never;
        Insert: {
          avatar_path?: string | null;
          created_at?: string;
          deleted_at?: string | null;
          display_name: string;
          id: string;
          updated_at?: string;
        };
        Update: {
          avatar_path?: string | null;
          created_at?: string;
          deleted_at?: string | null;
          display_name?: string;
          id?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      rating_history: {
        Row: {
          created_at: string;
          id: string;
          party_id: string;
          rating_after: number;
          rating_before: number;
          round_id: string;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          id?: string;
          party_id: string;
          rating_after: number;
          rating_before: number;
          round_id: string;
          user_id: string;
        };
        Update: {
          created_at?: string;
          id?: string;
          party_id?: string;
          rating_after?: number;
          rating_before?: number;
          round_id?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'rating_history_party_id_fkey';
            columns: ['party_id'];
            isOneToOne: false;
            referencedRelation: 'parties';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'rating_history_round_id_fkey';
            columns: ['round_id'];
            isOneToOne: false;
            referencedRelation: 'rounds';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'rating_history_user_id_fkey';
            columns: ['user_id'];
            isOneToOne: false;
            referencedRelation: 'profiles';
            referencedColumns: ['id'];
          },
        ];
      };
      reactions: {
        Row: {
          checkin_id: string;
          created_at: string;
          emoji: string;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          checkin_id: string;
          created_at?: string;
          emoji: string;
          user_id: string;
        };
        Update: {
          checkin_id?: string;
          created_at?: string;
          emoji?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'reactions_checkin_id_fkey';
            columns: ['checkin_id'];
            isOneToOne: false;
            referencedRelation: 'checkins';
            referencedColumns: ['id'];
          },
        ];
      };
      reports: {
        Row: {
          created_at: string;
          id: string;
          reason: string | null;
          reporter_id: string;
          status: Database['public']['Enums']['report_status'];
          target_id: string;
          target_type: Database['public']['Enums']['report_target'];
          updated_at: string;
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          id?: string;
          reason?: string | null;
          reporter_id: string;
          status?: Database['public']['Enums']['report_status'];
          target_id: string;
          target_type: Database['public']['Enums']['report_target'];
          updated_at?: string;
        };
        Update: {
          created_at?: string;
          id?: string;
          reason?: string | null;
          reporter_id?: string;
          status?: Database['public']['Enums']['report_status'];
          target_id?: string;
          target_type?: Database['public']['Enums']['report_target'];
          updated_at?: string;
        };
        Relationships: [];
      };
      round_members: {
        Row: {
          created_at: string;
          rating_before: number;
          round_id: string;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          rating_before: number;
          round_id: string;
          user_id: string;
        };
        Update: {
          created_at?: string;
          rating_before?: number;
          round_id?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'round_members_round_id_fkey';
            columns: ['round_id'];
            isOneToOne: false;
            referencedRelation: 'rounds';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'round_members_user_id_fkey';
            columns: ['user_id'];
            isOneToOne: false;
            referencedRelation: 'profiles';
            referencedColumns: ['id'];
          },
        ];
      };
      rounds: {
        Row: {
          created_at: string;
          ends_at: string;
          finalized_at: string | null;
          id: string;
          party_id: string;
          rule_version: number;
          starts_at: string;
          status: Database['public']['Enums']['round_status'];
          timezone: string;
          updated_at: string;
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          ends_at: string;
          finalized_at?: string | null;
          id?: string;
          party_id: string;
          rule_version: number;
          starts_at: string;
          status?: Database['public']['Enums']['round_status'];
          timezone: string;
          updated_at?: string;
        };
        Update: {
          created_at?: string;
          ends_at?: string;
          finalized_at?: string | null;
          id?: string;
          party_id?: string;
          rule_version?: number;
          starts_at?: string;
          status?: Database['public']['Enums']['round_status'];
          timezone?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'rounds_party_id_fkey';
            columns: ['party_id'];
            isOneToOne: false;
            referencedRelation: 'parties';
            referencedColumns: ['id'];
          },
        ];
      };
      votes: {
        Row: {
          checkin_id: string;
          created_at: string;
          voter_id: string;
        };
        ComputedFields: never;
        Insert: {
          checkin_id: string;
          created_at?: string;
          voter_id: string;
        };
        Update: {
          checkin_id?: string;
          created_at?: string;
          voter_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'votes_checkin_id_fkey';
            columns: ['checkin_id'];
            isOneToOne: false;
            referencedRelation: 'checkins';
            referencedColumns: ['id'];
          },
        ];
      };
      weekly_results: {
        Row: {
          computed_at: string;
          days_with_step_data: number;
          delta_r: number;
          place: number;
          round_id: string;
          rule_version: number;
          status: Database['public']['Enums']['result_status'];
          total_centipoints: number;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          computed_at?: string;
          days_with_step_data: number;
          delta_r: number;
          place: number;
          round_id: string;
          rule_version: number;
          status: Database['public']['Enums']['result_status'];
          total_centipoints: number;
          user_id: string;
        };
        Update: {
          computed_at?: string;
          days_with_step_data?: number;
          delta_r?: number;
          place?: number;
          round_id?: string;
          rule_version?: number;
          status?: Database['public']['Enums']['result_status'];
          total_centipoints?: number;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'weekly_results_round_id_fkey';
            columns: ['round_id'];
            isOneToOne: false;
            referencedRelation: 'rounds';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'weekly_results_user_id_fkey';
            columns: ['user_id'];
            isOneToOne: false;
            referencedRelation: 'profiles';
            referencedColumns: ['id'];
          },
        ];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      [_ in never]: never;
    };
    Enums: {
      card_kind: 'weekly_winner' | 'weekly_summary' | 'solo_weekly' | 'activity';
      dispute_status: 'open' | 'withdrawn' | 'resolved';
      dispute_target: 'daily_step_summary' | 'activity';
      point_flag: 'implausible_steps';
      report_status: 'open' | 'reviewed' | 'dismissed';
      report_target: 'checkin';
      result_status: 'provisional' | 'final';
      round_status: 'active' | 'provisional' | 'final';
      sport: 'walk' | 'run' | 'ride';
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>;

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, 'public'>];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
    ? (DefaultSchema['Tables'] & DefaultSchema['Views'])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema['Tables'] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema['Tables'] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    keyof DefaultSchema['Enums'] | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums']
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums'][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema['Enums']
    ? DefaultSchema['Enums'][DefaultSchemaEnumNameOrOptions]
    : never;

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    keyof DefaultSchema['CompositeTypes'] | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes']
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes'][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema['CompositeTypes']
    ? DefaultSchema['CompositeTypes'][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = {
  public: {
    Enums: {
      card_kind: ['weekly_winner', 'weekly_summary', 'solo_weekly', 'activity'],
      dispute_status: ['open', 'withdrawn', 'resolved'],
      dispute_target: ['daily_step_summary', 'activity'],
      point_flag: ['implausible_steps'],
      report_status: ['open', 'reviewed', 'dismissed'],
      report_target: ['checkin'],
      result_status: ['provisional', 'final'],
      round_status: ['active', 'provisional', 'final'],
      sport: ['walk', 'run', 'ride'],
    },
  },
} as const;
