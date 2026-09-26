#pragma once

#include <qstring.h>
#include <qvariantlist.h>

#include "settings/objectnode.hpp"
#include "common.hpp"
#include "enums.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;
using settings::vmap;

class PlayerAlias : public settings::ObjectNode {
    CONFIG_NODE(PlayerAlias, settings::ObjectNode)

    CONFIG_PROPERTY(QString, from, {})
    CONFIG_PROPERTY(QString, to, {})
};
CONFIG_LIST_TYPE(PlayerAlias, PlayerAliasList)

class ServiceGCalendar : public settings::ObjectNode {
    CONFIG_NODE(ServiceGCalendar, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, false) // Requires gws CLI in PATH
    CONFIG_PROPERTY(QString, command, u"gws"_s) // Path or name of the gws CLI binary
    CONFIG_PROPERTY(int, agendaDays, 30) // How many days ahead to fetch events
    CONFIG_PROPERTY(int, upcomingHours, 24) // Hours ahead to show in upcoming list
    CONFIG_PROPERTY(int, reminderMinutes, 10) // Minutes before event to send notification, 0 to disable
    CONFIG_PROPERTY(int, refreshInterval, 900) // Refresh interval in seconds
};

class ServiceClaudeUsage : public settings::ObjectNode {
    CONFIG_NODE(ServiceClaudeUsage, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, false) // Requires claude-usage-widget's CLI (pip install claude-usage-widget)
    CONFIG_PROPERTY(QString, command, u"claude-usage"_s) // Path or name of the claude-usage CLI binary
    CONFIG_PROPERTY(int, refreshInterval, 60) // Refresh interval in seconds
};

class ServiceAiCliUsage : public settings::ObjectNode {
    CONFIG_NODE(ServiceAiCliUsage, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, false) // Requires a local checkout of odrasile/ai-usage-widget with `npm ci` run in it
    CONFIG_PROPERTY(QString, repoPath, {}) // Absolute path to the ai-usage-widget checkout (containing backend/index.js)
    CONFIG_PROPERTY(QString, nodeCommand, u"node"_s) // Path or name of the node binary
    CONFIG_PROPERTY(int, refreshInterval, 300) // Refresh interval in seconds (PTY-based queries are slow, so keep this long)
};

class ServiceConfig : public settings::ObjectNode {
    CONFIG_NODE(ServiceConfig, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(QString, weatherLocation, {})
    // Auto guesses based on locale
    CONFIG_GLOBAL_ENUM_PROPERTY(TemperatureUnit, weatherUnits, TemperatureUnit::Auto)
    // Always Celsius by default cause apparently even imperial system users don't use Fahrenheit for perf temps?
    CONFIG_GLOBAL_ENUM_PROPERTY(TemperatureUnit, sensorUnits, TemperatureUnit::Celsius)
    // Binary (KiB/MiB/GiB) or decimal (KB/MB/GB) data sizes
    CONFIG_GLOBAL_ENUM_PROPERTY(DataUnit, dataUnits, DataUnit::Binary)
    CONFIG_GLOBAL_ENUM_PROPERTY(ClockFormat, clockFormat, ClockFormat::Auto)
    CONFIG_GLOBAL_ENUM_PROPERTY(GpuType, gpuType, GpuType::Auto)
    CONFIG_GLOBAL_PROPERTY(int, visualiserBars, 60)
    CONFIG_GLOBAL_PROPERTY(qreal, audioIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, brightnessIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, maxVolume, 1.0)
    CONFIG_GLOBAL_PROPERTY(bool, smartScheme, true)
    CONFIG_GLOBAL_PROPERTY(QString, defaultPlayer, u"Spotify"_s)
    CONFIG_GLOBAL_LIST(PlayerAliasList, playerAliases,
        DEFAULT_ARG({
            vmap({ { u"from"_s, u"com.github.th_ch.youtube_music"_s }, { u"to"_s, u"YT Music"_s } }),
        }))
    CONFIG_GLOBAL_ENUM_PROPERTY(LyricsBackend, lyricsBackend, LyricsBackend::Auto)
    CONFIG_GLOBAL_SUBOBJECT(ServiceGCalendar, calendar)
    CONFIG_GLOBAL_SUBOBJECT(ServiceClaudeUsage, claudeUsage)
    CONFIG_GLOBAL_SUBOBJECT(ServiceAiCliUsage, aiCliUsage)
};

} // namespace caelestia::config
