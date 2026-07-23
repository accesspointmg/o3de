/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */

#include <GemRepo/GemRepoAddDialog.h>
#include <FormFolderBrowseEditWidget.h>
#include <AzCore/Utils/Utils.h>
#include <PythonBindingsInterface.h>
#include <QVBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QDialogButtonBox>
#include <QPushButton>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QAbstractItemView>
#include <QListView>
#include <QStandardItemModel>
#include <QLocale>
#include <QUrl>

namespace O3DE::ProjectManager
{
    GemRepoAddDialog::GemRepoAddDialog(QWidget* parent)
        : QDialog(parent)
    {
        setWindowTitle(tr("Add a User Repository"));
        setModal(true);
        setObjectName("addGemRepoDialog");

        QVBoxLayout* vLayout = new QVBoxLayout();
        vLayout->setContentsMargins(30, 30, 25, 10);
        vLayout->setSpacing(0);
        vLayout->setAlignment(Qt::AlignTop);
        setLayout(vLayout);

        QLabel* instructionTitleLabel = new QLabel(tr("Enter a valid path to add a new user repository"));
        instructionTitleLabel->setObjectName("gemRepoAddDialogInstructionTitleLabel");
        instructionTitleLabel->setAlignment(Qt::AlignLeft);
        vLayout->addWidget(instructionTitleLabel);

        vLayout->addSpacing(10);

        QLabel* instructionContextLabel = new QLabel(tr("The path can be a Repository URL or a Local Path in your directory."));
        instructionContextLabel->setAlignment(Qt::AlignLeft);
        vLayout->addWidget(instructionContextLabel);

        m_repoPath = new FormFolderBrowseEditWidget(tr("Repository Path"), "", this);
        m_repoPath->setFixedSize(QSize(600, 100));
        vLayout->addWidget(m_repoPath);

        vLayout->addSpacing(10);

        QLabel* curatedReposLabel = new QLabel(tr("Curated Repos"));
        curatedReposLabel->setToolTip(
            "The criteria needed for a repo to be curated is: All objects in the repo have to be LEGAL, maintained, safe, and useful. "
            "What repos are curated or not start as a github pull request in which repo(s) are added with your best arguments "
            "as to why you think the repo(s) meets the criteria. You have to convince 2 maintainers and ultimately the O3DE director to be added to curated. "
            "Anyone can petition/create a pull request to have any repo added to curated if they believe it meets the criteria. "
            "Curated repos are NOT considered to be O3DE canonical repos and thus O3DE DOES NOT vet the contents of ANY repos other than O3DE canonical repos. "
            "O3DE offers no guarantee, stated or implied, of fitness for any particular use and assumes no liability for the contents of any curated repo. "
            "Curated repos are only reviewed that they meet the criteria at the time of inclusion and at such time anyone raises an issue that they "
            "believe a curated repo no longer meets the criteria. "
            "If there is found to be a lapse in any criteria after inclusion, the repo may be demoted to uncurated or removed and the owner/petitioner may or may not be notified. "
            "O3DE reserves the right to demote or remove any repo at any time for any reason, including no reason. "
            "If a DMCA takedown or other legal challenge is issued against any curated repo or if anything ILLEGAL is reported or any violation by sanctioned "
            "entity occurs the repo will be removed immediately, even if ultimately found to be unjustified while it is being investigated. If found to be unjustified the repo may be reinstated. "
            "Demoted or removed repos maybe also be reinstated if a reason for demotion or removal was given and the issue was sufficiently remediated. "
            "If any repo is demoted or removed, anyone may appeal that decision directly to the TSC. "
            "!!!SO PROCEED WITH CAUTION WHEN USING ANY NON CANONICAL REPO!!! "
        );
        curatedReposLabel->setAlignment(Qt::AlignLeft);
        vLayout->addWidget(curatedReposLabel);

        m_curatedRepos = new QListView();
        m_curatedRepos->setStyleSheet("QListView { border: 1px solid white; }");
        m_curatedRepos->setSelectionMode(QAbstractItemView::SingleSelection);
        m_curatedRepos->setFixedSize(QSize(600, 100));
        m_curatedRepos->setObjectName("gemRepoAddDialogCuratedRepos");
        m_curatedRepos->setEditTriggers(QListView::NoEditTriggers);

        m_curatedReposModel = new QStandardItemModel(this);
        m_curatedRepos->setModel(m_curatedReposModel);

        vLayout->addWidget(m_curatedRepos);

        QLocale locale = QLocale::system(); 
#if QT_VERSION >= QT_VERSION_CHECK(6, 2, 0)
        QString countryCode = QLocale::territoryToCode(locale.territory()).toLower();
#else
        // Qt 5: no territoryToCode/countryToCode; derive from locale name "lang_COUNTRY"
        QString countryCode = locale.name().section('_', 1, 1).toLower();
#endif
        QString countryCurated = QString("https://canonical.o3de.org/countries/%1/curated/repo.json").arg(countryCode);

        QString curated_repos = PythonBindingsInterface::Get()->GetCacheFile(countryCurated);
        QFile curatedFile(curated_repos);
        if (curatedFile.open(QIODevice::ReadOnly | QIODevice::Text))
        {
            QByteArray jsonData = curatedFile.readAll();
            curatedFile.close();

            QJsonDocument document = QJsonDocument::fromJson(jsonData);
            QJsonObject jsonObject = document.object();
            if (jsonObject.contains("repos") && jsonObject["repos"].isArray())
            {
                QJsonArray curatedRepos = jsonObject["repos"].toArray();
                for (const QJsonValue& value : qAsConst(curatedRepos))
                {
                    QStandardItem* item = new QStandardItem(value.toString());
                    m_curatedReposModel->appendRow(item);
                }
            }
        }

        connect(
            m_curatedRepos->selectionModel(),
            &QItemSelectionModel::selectionChanged,
            [=](const QItemSelection& /*selected*/, const QItemSelection& /*deselected*/)
            {
            QModelIndex index = m_curatedRepos->currentIndex();
            QString itemText = index.data(Qt::DisplayRole).toString();
            m_repoPath->lineEdit()->setText(itemText);
            }
        );

        vLayout->addSpacing(10);

        QLabel* uncuratedReposLabel = new QLabel(tr("Uncurated Repos"));
        uncuratedReposLabel->setToolTip(
            "The criteria needed for a repo to be included as uncurated is: All objects in the repo must be LEGAL. "
            "What repos are uncurated or not start as a github pull request in which repo(s) are added with your best arguments "
            "as to why you think the repo(s) meets the criteria. You have to convince 2 maintainers to be added to uncurated. "
            "Uncurated repos are NOT considered to be O3DE canonical repos and thus O3DE DOES NOT vet the contents of ANY repos other than O3DE canonical repos. "
            "O3DE offers no guarantee, stated or implied, of fitness for any particular use and assumes no liability for the contents of any uncurated repo. "
            "Uncurated repos are only reviewed that they meet the criteria at the time of inclusion and at such time anyone raises an issue that they "
            "believe an uncurated repo no longer meets the criteria. "
            "O3DE reserves the right to demote or remove any repo at any time for any reason, including no reason. "
            "If a DMCA takedown or other legal challenge is issued against any uncurated repo or if anything ILLEGAL is reported or any violation by sanctioned "
            "entity occurs the repo will be removed immediately, even if ultimately found to be unjustified while it is being investigated. If found to be unjustified the repo may be reinstated. "
            "Demoted or removed repos maybe also be reinstated if a reason for demotion or removal was given and the issue was sufficiently remediated. "
            "If any repo is demoted or removed, anyone may appeal that decision directly to the TSC. "
            "!!!SO PROCEED WITH CAUTION WHEN USING ANY NON CANONICAL REPO!!! "
        );
        uncuratedReposLabel->setAlignment(Qt::AlignLeft);
        vLayout->addWidget(uncuratedReposLabel);

        m_uncuratedRepos = new QListView();
        m_uncuratedRepos->setStyleSheet("QListView { border: 1px solid white; }");
        m_uncuratedRepos->setSelectionMode(QAbstractItemView::SingleSelection);
        m_uncuratedRepos->setFixedSize(QSize(600, 100));
        m_uncuratedRepos->setObjectName("gemRepoAddDialogCommunityRepos");
        m_uncuratedRepos->setEditTriggers(QListView::NoEditTriggers);

        m_uncuratedReposModel = new QStandardItemModel(this);
        m_uncuratedRepos->setModel(m_uncuratedReposModel);

        vLayout->addWidget(m_uncuratedRepos);

        QString countryUncurated = QString("https://canonical.o3de.org/countries/%1/uncurated/repo.json").arg(countryCode);

        QString uncurated_repos = PythonBindingsInterface::Get()->GetCacheFile(countryUncurated);
        QFile file(uncurated_repos);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text))
        {
            QByteArray jsonData = file.readAll();
            file.close();

            QJsonDocument document = QJsonDocument::fromJson(jsonData);
            QJsonObject jsonObject = document.object();
            if (jsonObject.contains("repos") && jsonObject["repos"].isArray())
            {
                QJsonArray communityRepos = jsonObject["repos"].toArray();
                for (const QJsonValue& value : qAsConst(communityRepos))
                {
                    QStandardItem* item = new QStandardItem(value.toString());
                    m_uncuratedReposModel->appendRow(item);
                }
            }
        }

        connect(
            m_uncuratedRepos->selectionModel(),
            &QItemSelectionModel::selectionChanged,
            [=](const QItemSelection& /*selected*/, const QItemSelection& /*deselected*/)
            {
                QModelIndex index = m_uncuratedRepos->currentIndex();
                QString itemText = index.data(Qt::DisplayRole).toString();
                m_repoPath->lineEdit()->setText(itemText);
            }
        );

        vLayout->addSpacing(10);

        QLabel* warningLabel = new QLabel(tr("Online repositories may contain files that could potentially harm your computer,"
            " please ensure you understand the risks before downloading o3de objects from third-party sources."));
        warningLabel->setObjectName("gemRepoAddDialogWarningLabel");
        warningLabel->setWordWrap(true);
        warningLabel->setAlignment(Qt::AlignLeft);
        vLayout->addWidget(warningLabel);

        vLayout->addSpacing(40);

        QDialogButtonBox* dialogButtons = new QDialogButtonBox();
        dialogButtons->setObjectName("footer");
        vLayout->addWidget(dialogButtons);

        QPushButton* cancelButton = dialogButtons->addButton(tr("Cancel"), QDialogButtonBox::RejectRole);
        cancelButton->setProperty("secondary", true);
        QPushButton* applyButton = dialogButtons->addButton(tr("Add"), QDialogButtonBox::ApplyRole);
        applyButton->setProperty("primary", true);

        connect(cancelButton, &QPushButton::clicked, this, &QDialog::reject);
        connect(applyButton, &QPushButton::clicked, this, &QDialog::accept);
    }

    QString GemRepoAddDialog::GetRepoPath()
    {
        return m_repoPath->lineEdit()->text();
    }
} // namespace O3DE::ProjectManager
