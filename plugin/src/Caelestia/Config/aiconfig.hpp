#pragma once

#include <qstring.h>
#include <qvariantlist.h>

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class AiPolicies : public settings::ObjectNode {
    CONFIG_NODE(AiPolicies, settings::ObjectNode)

    // 0 = allow all, 1 = warn for online, 2 = block online models
    CONFIG_PROPERTY(int, restrictOnlineModels, 0)
};

class AiConfig : public settings::ObjectNode {
    CONFIG_NODE(AiConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(QString, model, u"gemini-2.0-flash"_s)
    CONFIG_PROPERTY(QString, tool, u"search"_s)
    CONFIG_PROPERTY(qreal, temperature, 0.5)
    CONFIG_PROPERTY(QString, systemPrompt, {})
    CONFIG_PROPERTY(QVariantList, extraModels, {})
    CONFIG_SUBOBJECT(AiPolicies, policies)
};

} // namespace caelestia::config
